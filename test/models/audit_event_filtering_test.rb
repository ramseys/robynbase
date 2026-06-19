require 'test_helper'

# Unit tests for the admin activity-list filter scopes. Because the filtering now
# lives on the model, these exercise it directly — no PaperTrail, no controller,
# no HTTP — by creating audit_events rows and asserting what each scope selects.
class AuditEventFilteringTest < ActiveSupport::TestCase
  setup do
    # Times are UTC and days apart, so local-zone day boundaries can't flip them.
    @gig   = AuditEvent.create!(transaction_id: 1, primary_item_type: "Gig",
                                event: "update",  whodunnit: "5", created_at: Time.utc(2026, 6, 1, 12))
    @song  = AuditEvent.create!(transaction_id: 2, primary_item_type: "Song",
                                event: "create",  whodunnit: "7", created_at: Time.utc(2026, 6, 10, 12))
    @venue = AuditEvent.create!(transaction_id: 3, primary_item_type: "Venue",
                                event: "destroy", whodunnit: "5", created_at: Time.utc(2026, 6, 20, 12))
  end

  test "of_item_type selects only that primary_item_type" do
    assert_equal [@gig], AuditEvent.of_item_type("Gig").to_a
  end

  test "of_event selects only that event" do
    assert_equal [@song], AuditEvent.of_event("create").to_a
  end

  test "by_actor selects only that whodunnit" do
    assert_equal [@gig.id, @venue.id].sort, AuditEvent.by_actor("5").pluck(:id).sort
  end

  test "blank filter arguments are no-ops" do
    assert_equal 3, AuditEvent.of_item_type("").count
    assert_equal 3, AuditEvent.of_event(nil).count
    assert_equal 3, AuditEvent.by_actor("").count
  end

  test "created_on_or_after includes the whole start day and later" do
    result = AuditEvent.created_on_or_after("2026-06-10")
    assert_includes result, @song
    assert_includes result, @venue
    assert_not_includes result, @gig
  end

  test "created_on_or_before is inclusive of the whole end day" do
    result = AuditEvent.created_on_or_before("2026-06-10")
    assert_includes result, @gig
    assert_includes result, @song # 12:00 on the end day is still before end-of-day
    assert_not_includes result, @venue
  end

  test "blank or invalid dates are no-ops" do
    assert_equal 3, AuditEvent.created_on_or_after("").count
    assert_equal 3, AuditEvent.created_on_or_before("not-a-date").count
  end

  test "scopes and date filters chain" do
    result = AuditEvent.of_item_type("Gig").by_actor("5").created_on_or_after("2026-05-01")
    assert_equal [@gig], result.to_a
  end
end
