# Shared PaperTrail configuration for the app's audited records (Gig, Song,
# Composition, Venue and their child rows). See
# docs/plans/auditing/3-record-change-tracking-plan.md.
#
# Each including model must define an #audit_name returning a stable,
# human-readable label; it is stored on the version at write time via
# `meta: { item_name: :audit_name }`. #audit_name is also evaluated for destroy
# events, so it must not depend on associations removed in the same transaction.
module Auditable
  extend ActiveSupport::Concern

  # Names of models that have called `audited`. Stored as strings (not class objects)
  # so the list survives dev code reloading; AuditHierarchy uses it to enumerate the
  # top-level types.
  @audited_models = []

  def self.audited_models
    @audited_models
  end

  def self.register(model_name)
    @audited_models |= [model_name]
  end

  class_methods do
    # Enable auditing with this app's conventions.
    # skip: columns to exclude from object_changes (e.g. auto-updating timestamps).
    def audited(skip: [])
      Auditable.register(name)
      has_paper_trail on: %i[create update destroy],
                      meta: { item_name: :audit_name },
                      skip: skip
    end
  end
end
