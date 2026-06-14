# Derives the audited record hierarchy from ActiveRecord associations rather than a
# hand-maintained list. A record is a "child" when it belongs_to a parent that owns
# its lifecycle (the parent declares has_many/has_one ... dependent: :destroy);
# otherwise it is top-level. This is how a child-only edit (e.g. a setlist reorder,
# which writes no Gig version) is still headlined by its owning parent, and it is
# intended to drive revert ordering too.
#
# `dependent: :destroy` is thus load-bearing for the audit trail. test/models/
# audit_hierarchy_test.rb pins the derived classification so an association change
# that would silently re-classify a record fails a named test instead of quietly
# altering the audit history.
#
# Computed on demand (no memoization) so it stays correct across dev code reloads;
# the call sites are not hot loops.
module AuditHierarchy
  module_function

  # has_many/has_one dependent that means "the parent owns this record". Only
  # :destroy qualifies: it instantiates each child and runs callbacks, so PaperTrail
  # records the cascade. :delete_all/:delete delete via raw SQL and skip callbacks,
  # so they must NOT mark ownership of an audited child (see #unsafe_owned_children).
  OWNERSHIP_DEPENDENTS = %i[destroy].freeze

  # Dependent options that delete children without running callbacks, so PaperTrail
  # never records the deletion. An audited child owned this way would silently lose
  # its cascade deletes from the audit trail.
  CALLBACK_SKIPPING_DEPENDENTS = %i[delete_all delete].freeze

  # The belongs_to reflection linking a child to its owning parent, or nil when the
  # record is top-level. Accepts a class or an item_type string (so it works for a
  # destroyed row, where only the type name survives).
  def owner_reflection(item_type)
    klass = to_class(item_type)
    return nil unless klass
    klass.reflect_on_all_associations(:belongs_to).find do |belong|
      parent = association_target(belong)
      parent && owns?(parent, klass)
    end
  end

  # True for an audited record that no parent owns (Gig, Composition, Song, Venue).
  def top_level?(item_type)
    klass = to_class(item_type)
    klass.present? && audited?(klass) && owner_reflection(klass).nil?
  end

  def child?(item_type)
    owner_reflection(item_type).present?
  end

  # All audited types with no owning parent, e.g. %w[Composition Gig Song Venue].
  def top_level_types
    Auditable.audited_models.reject { |name| child?(name) }
  end

  # Owning has_many/has_one reflections that would cascade-delete an audited child
  # without callbacks (dependent: :delete_all/:delete), so PaperTrail can't record
  # the deletion. Should always be empty; pinned by audit_hierarchy_test.rb.
  def unsafe_owned_children
    Auditable.audited_models.flat_map do |name|
      klass = name.safe_constantize
      next [] unless klass
      (klass.reflect_on_all_associations(:has_many) +
       klass.reflect_on_all_associations(:has_one)).select do |reflection|
        CALLBACK_SKIPPING_DEPENDENTS.include?(reflection.options[:dependent]) &&
          (target = association_target(reflection)) && audited?(target)
      end
    end
  end

  def to_class(item_type)
    item_type.is_a?(Class) ? item_type : item_type.to_s.safe_constantize
  end

  def audited?(klass)
    Auditable.audited_models.include?(klass.name)
  end

  # belongs_to#klass raises for a polymorphic association (no single target); such an
  # association can never be an owning relationship here, so treat it as no target.
  def association_target(reflection)
    reflection.klass
  rescue StandardError
    nil
  end

  def owns?(parent, child)
    (parent.reflect_on_all_associations(:has_many) +
     parent.reflect_on_all_associations(:has_one)).any? do |reflection|
      OWNERSHIP_DEPENDENTS.include?(reflection.options[:dependent]) &&
        association_target(reflection) == child
    end
  end
end
