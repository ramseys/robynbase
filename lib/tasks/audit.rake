# Diagnostics for the PaperTrail audit trail.
# See docs/plans/auditing/3-record-change-tracking-plan.md.
namespace :audit do

  # Pre-flight data-integrity check: orphaned child/foreign rows that would make
  # the audit output inconsistent. SONGID is nullable on GSET/TRAK, so NULLs are fine.
  desc "Report orphaned rows in audited tables (read-only)"
  task integrity: :environment do
    checks = {
      "GSET rows with GIGID not in GIG" =>
        "SELECT COUNT(*) FROM GSET WHERE GIGID IS NOT NULL AND GIGID > 0 AND GIGID NOT IN (SELECT GIGID FROM GIG)",
      "GSET rows with SONGID not in SONG" =>
        "SELECT COUNT(*) FROM GSET WHERE SONGID IS NOT NULL AND SONGID > 0 AND SONGID NOT IN (SELECT SONGID FROM SONG)",
      "TRAK rows with COMPID not in COMP" =>
        "SELECT COUNT(*) FROM TRAK WHERE COMPID IS NOT NULL AND COMPID > 0 AND COMPID NOT IN (SELECT COMPID FROM COMP)",
      "TRAK rows with SONGID not in SONG" =>
        "SELECT COUNT(*) FROM TRAK WHERE SONGID IS NOT NULL AND SONGID > 0 AND SONGID NOT IN (SELECT SONGID FROM SONG)",
      "GIG rows with VENUEID not in VENUE" =>
        "SELECT COUNT(*) FROM GIG WHERE VENUEID IS NOT NULL AND VENUEID > 0 AND VENUEID NOT IN (SELECT VENUEID FROM VENUE)"
    }

    total = 0
    checks.each do |label, sql|
      count = ActiveRecord::Base.connection.select_value(sql).to_i
      total += count
      flag = count.zero? ? "OK " : "!! "
      puts "#{flag} #{label}: #{count}"
    end

    puts total.zero? ? "\nNo orphaned rows found." : "\n#{total} orphaned row(s) found — investigate before relying on audit output."
  end

  # Rebuild the audit_events summary from the raw versions table. Useful if the
  # after_create maintenance ever skipped rows (failures are logged, not raised).
  desc "Rebuild audit_events from versions"
  task rebuild_events: :environment do
    AuditEvent.delete_all
    grouped = PaperTrail::Version.where.not(transaction_id: nil).order(:id).group_by(&:transaction_id)
    grouped.each_value do |versions|
      event = AuditEvent.new(transaction_id: versions.first.transaction_id)
      versions.each { |version| event.apply(version) }
      event.save!
    end
    puts "Rebuilt #{grouped.size} audit_event(s) from #{PaperTrail::Version.count} version(s)."
  end
end
