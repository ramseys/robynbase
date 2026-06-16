require 'test_helper'

# Pins the audit hierarchy that AuditHierarchy derives from ActiveRecord associations.
# Because `dependent: :destroy` is what marks an owning relationship, an association
# change that would silently re-classify an audited record (e.g. dropping
# dependent: :destroy, or adding a new owned child) fails here instead of quietly
# altering the audit trail / revert behaviour.
class AuditHierarchyTest < ActiveSupport::TestCase
  test "top-level audited types are exactly the parent records" do
    Rails.application.eager_load! # ensure every `audited` model has registered
    assert_equal %w[Composition Gig Song Venue], AuditHierarchy.top_level_types.sort
  end

  test "child records resolve to their owning parent" do
    { Gigset => Gig, Track => Composition, GigMedium => Gig }.each do |child, owner|
      reflection = AuditHierarchy.owner_reflection(child)
      assert_not_nil reflection, "#{child} should have an owning parent"
      assert_equal owner, reflection.klass, "#{child} should be owned by #{owner}"
      assert_not AuditHierarchy.top_level?(child), "#{child} is a child, not top-level"
      assert AuditHierarchy.child?(child)
    end
  end

  test "a referenced-but-not-owned association is not mistaken for the owner" do
    # Gigset belongs_to :song, but Song does not own gigsets (no dependent: :destroy),
    # so the owner must be Gig, never Song. Likewise Gig belongs_to :venue but is
    # top-level because Venue does not own gigs.
    assert_equal Gig, AuditHierarchy.owner_reflection(Gigset).klass
    assert AuditHierarchy.top_level?(Gig)
  end

  test "resolves from an item_type string, as needed for destroyed rows" do
    assert AuditHierarchy.top_level?("Gig")
    assert_equal Gig, AuditHierarchy.owner_reflection("Gigset").klass
  end

  test "the audited registry matches the models PaperTrail actually tracks" do
    # Auditable.audited_models is maintained by the `audited` concern, which also
    # applies this app's PaperTrail conventions (on: events, the item_name meta,
    # skip:). Calling has_paper_trail directly would track a model while bypassing
    # those conventions and leaving it invisible to AuditHierarchy. PaperTrail keeps
    # no global list of tracked models, so reconstruct it: has_paper_trail mixes
    # PaperTrail::Model::InstanceMethods into the model (the gem itself uses this to
    # detect a double-call). The superclass check keeps only the class that
    # introduced auditing, not any inheriting STI subclass.
    Rails.application.eager_load!
    marker = PaperTrail::Model::InstanceMethods
    paper_trailed = ApplicationRecord.descendants.select do |klass|
      klass < marker && !(klass.superclass < marker)
    end.map(&:name)

    assert_equal Auditable.audited_models.sort, paper_trailed.sort,
      "PaperTrail-tracked models and the audited registry have diverged. Use the " \
      "`audited` concern instead of has_paper_trail directly so the app's auditing " \
      "conventions are applied and AuditHierarchy stays aware of the model."
  end

  test "no audited child is owned through a callback-skipping dependent" do
    # dependent: :delete_all/:delete remove children via raw SQL, skipping the
    # callbacks PaperTrail relies on, so their cascade deletes would never be
    # audited. Such a child must use dependent: :destroy instead.
    Rails.application.eager_load!
    offenders = AuditHierarchy.unsafe_owned_children.map do |reflection|
      "#{reflection.active_record}##{reflection.name} (dependent: #{reflection.options[:dependent]})"
    end
    assert_empty offenders,
      "These associations cascade-delete audited children without callbacks, so " \
      "PaperTrail won't record the deletions — use dependent: :destroy: #{offenders.join(', ')}"
  end
end
