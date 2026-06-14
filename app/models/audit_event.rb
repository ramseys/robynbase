# Denormalized one-row-per-transaction summary of audited activity, maintained
# from PaperTrail::Version after_create (callback registered in
# config/initializers/paper_trail.rb). Lets the admin activity list paginate and
# filter without grouping the fast-growing `versions` table by transaction_id.
#
# See docs/plans/auditing/3-record-change-tracking-plan.md.
class AuditEvent < ApplicationRecord

  # Filters for the admin activity list. Each is a no-op when its argument is
  # blank, so the controller can chain them all and let blank params fall through.
  scope :of_item_type, ->(item_type) { where(primary_item_type: item_type) if item_type.present? }
  scope :of_event,     ->(event)     { where(event: event)                 if event.present? }
  scope :by_actor,     ->(whodunnit) { where(whodunnit: whodunnit)         if whodunnit.present? }

  # Date-range filters. Written as class methods rather than `scope` because they
  # parse their string argument (and need a private helper); each returns `all`
  # when the date is blank/invalid so it stays chainable. The end bound is
  # inclusive of the whole day.
  def self.created_on_or_after(date_string)
    date = parse_filter_date(date_string)
    date ? where("audit_events.created_at >= ?", date.beginning_of_day) : all
  end

  def self.created_on_or_before(date_string)
    date = parse_filter_date(date_string)
    date ? where("audit_events.created_at < ?", date.end_of_day) : all
  end

  def self.parse_filter_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end
  private_class_method :parse_filter_date

  # Fold a freshly created version into its transaction's summary row. Runs inside
  # the version's create, i.e. the same DB transaction as the original write.
  # Never allowed to break that write: a summary failure is logged, leaving the raw
  # versions intact for a later rebuild.
  def self.record_version(version)
    # The first version in a transaction is inserted with a nil transaction_id;
    # PT-AT then sets it to the version's own id (the value every later version in
    # the transaction shares). So at after_create time, fall back to version.id.
    transaction_id = version.transaction_id || version.id

    event = find_or_initialize_by(transaction_id: transaction_id)
    event.apply(version)
    event.save!
  rescue StandardError => e
    Rails.logger.error("AuditEvent.record_version failed for version #{version.id}: #{e.class}: #{e.message}")
    nil
  end

  # Merge one version into this summary: bump counts and adopt it as the headline
  # if appropriate (see #adopt_headline).
  def apply(version)
    self.whodunnit ||= version.whodunnit
    self.created_at ||= version.created_at
    self.version_count = version_count.to_i + 1

    counts = summary || {}
    by_event = counts[version.item_type] || {}
    by_event[version.event] = by_event[version.event].to_i + 1
    counts[version.item_type] = by_event
    self.summary = counts

    adopt_headline(version)
  end

  # Choose the headline this version contributes to the activity:
  #
  # * A real parent version (Gig, Composition, ...) is the headline outright. The
  #   first one seen wins; it always supersedes a previously elevated child (see
  #   below), so a Gig's own destroy version beats the child destroys that precede
  #   it in the transaction.
  # * A child-only transaction (e.g. a setlist edit that did not change any GIG
  #   column, so no Gig version exists) is elevated to stand in its owning parent,
  #   with the action recorded as "update" because the parent was modified through
  #   its children. `primary_elevated` remembers this so a later real parent can
  #   still take over.
  def adopt_headline(version)
    if AuditHierarchy.top_level?(version.item_type)
      if primary_item_type.nil? || primary_elevated?
        set_primary(version.item_type, version.item_id, version.item_name, version.event)
        self.primary_elevated = false
      end
    elsif primary_item_type.nil?
      owner = owner_for(version)
      if owner
        set_primary(owner.class.name, owner.id, owner.audit_name, "update")
      else
        set_primary(version.item_type, version.item_id, version.item_name, version.event)
      end
      self.primary_elevated = true
    end
  end

  # The live primary record, or nil if it has since been deleted (use item_name then).
  def primary_item
    return nil if primary_item_type.blank? || primary_item_id.blank?
    klass = primary_item_type.constantize
    klass.find_by(klass.primary_key => primary_item_id)
  end

  # Resolves a whodunnit (a user id, or a "system:*" label) to something printable.
  def self.label_for(whodunnit)
    return "Unknown" if whodunnit.blank?
    if whodunnit.match?(/\A\d+\z/)
      user = User.find_by(id: whodunnit)
      user ? (user.email.presence || "User ##{whodunnit}") : "User ##{whodunnit}"
    else
      whodunnit
    end
  end

  def actor_label
    self.class.label_for(whodunnit)
  end

  # Short description of the child-row changes, e.g. "2 setlist, 1 media".
  def summary_text
    (summary || {}).reject { |type, _| type == primary_item_type }.map do |type, by_event|
      "#{by_event.values.sum} #{type.underscore.humanize.downcase}"
    end.join(", ")
  end

  private

  def set_primary(item_type, item_id, item_name, event)
    self.primary_item_type = item_type
    self.primary_item_id   = item_id
    self.item_name         = item_name
    self.event             = event
  end

  # The owning parent of a child version (Gigset -> Gig, Track -> Composition,
  # GigMedium -> Gig), or nil if the version is top-level / unresolvable. The owning
  # association is derived from the schema by AuditHierarchy.
  def owner_for(version)
    # version.item resolves the live row via the polymorphic association (honouring
    # the legacy primary keys); for a destroy the row is gone, so reify it instead.
    record = version.event == "destroy" ? version.reify : version.item
    reflection = record && AuditHierarchy.owner_reflection(record.class)
    reflection ? record.public_send(reflection.name) : nil
  end
end
