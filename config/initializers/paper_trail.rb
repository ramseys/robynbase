# PaperTrail is installed in "transaction_id-only" mode for this phase: versions are
# grouped by transaction_id (supplied by paper_trail-association_tracking), but we do
# NOT track associations. Job B (version_associations writes + reify-with-associations)
# is only needed for graph reverts, which are out of scope here.
# See docs/plans/auditing/3-record-change-tracking-plan.md ("Why PT-AT, and in which mode").
# Store object/object_changes as JSON rather than the default YAML. YAML dumps typed
# attribute values as embedded Ruby objects (datetimes as ActiveSupport::TimeWithZone,
# decimals as BigDecimal); PaperTrail then deserializes with YAML.safe_load, which
# refuses those classes and fails the whole parse, so the affected version shows no
# field changes at all. JSON encodes such values as plain strings/numbers and avoids
# this entirely.
PaperTrail.serializer = PaperTrail::Serializers::JSON

PaperTrail.config.track_associations = false

# Maintain the denormalized audit_events summary (one row per transaction) as
# versions are written. Registered here once at boot; PaperTrail::Version is a gem
# class that is not reloaded, and AuditEvent is resolved at call time.
PaperTrail::Version.after_create do |version|
  AuditEvent.record_version(version)
end
