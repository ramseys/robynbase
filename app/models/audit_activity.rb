# Read-side presenter for a single grouped activity (all versions sharing a
# transaction_id). Turns raw PaperTrail versions into the parent field diff and
# the added / removed / reordered / changed child-row summary the detail view shows.
#
# See docs/plans/auditing/3-record-change-tracking-plan.md ("Build an audit summary layer").
class AuditActivity

  # Columns whose change, on its own, means a row was merely reordered.
  ORDER_COLUMNS = {
    "Gigset"    => "Chrono",
    "Track"     => "Seq",
    "GigMedium" => "Chrono"
  }.freeze

  attr_reader :transaction_id

  def initialize(transaction_id)
    @transaction_id = transaction_id
  end

  def versions
    @versions ||= PaperTrail::Version.where(transaction_id: transaction_id).order(:id).to_a
  end

  def exists?
    versions.any?
  end

  def event
    @event ||= AuditEvent.find_by(transaction_id: transaction_id)
  end

  # The headline version: the parent record's own version, or nil for a child-only
  # transaction (e.g. a setlist edit) where no parent row changed. In that case the
  # headline label comes from the elevated AuditEvent (see #headline_*), and every
  # version is a child row.
  def primary_version
    versions.find { |v| AuditHierarchy.top_level?(v.item_type) }
  end

  def child_versions
    versions - [primary_version]
  end

  # Headline shown at the top of the detail view. Prefers the denormalized
  # AuditEvent (which elevates a child-only transaction to its owning parent),
  # falling back to the raw parent version.
  def headline_type
    event&.primary_item_type || primary_version&.item_type
  end

  def headline_name
    event&.item_name || primary_version&.item_name
  end

  def headline_event
    event&.event || primary_version&.event
  end

  # Field diffs for the headline record: { "Field" => [old, new], ... }.
  def parent_changes
    changeset(primary_version)
  end

  # Child versions grouped by item type, each classified and carrying its diff:
  # { "Gigset" => [{ version:, label:, kind:, changes: }, ...], ... }
  def child_groups
    child_versions.group_by(&:item_type).transform_values do |group|
      group.map do |version|
        {
          version: version,
          label:   version.item_name,
          kind:    classify(version),
          changes: changeset(version)
        }
      end
    end
  end

  private

  def changeset(version)
    return {} if version.nil?
    version.changeset || {}
  end

  # added / removed / reordered / changed
  def classify(version)
    kind = case version.event
           when "create"  then :added
           when "destroy" then :removed
           else reorder_or_change(version)
           end
    kind
  end

  def reorder_or_change(version)
    order_column = ORDER_COLUMNS[version.item_type]
    changed_keys = changeset(version).keys
    if order_column && changed_keys.any? && (changed_keys - [order_column]).empty?
      :reordered
    else
      :changed
    end
  end
end
