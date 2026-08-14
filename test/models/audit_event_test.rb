require 'test_helper'

# Population of the denormalized audit_events summary and the AuditActivity
# presenter. Each test performs exactly one versioned logical transaction so it
# works under transactional fixtures (see with_versioning note in test_helper).
class AuditEventTest < ActiveSupport::TestCase

  test "a composition and its tracks form one grouped audit_event" do
    with_versioning do
      comp = Composition.create!(Title: "ZZ Grouped Album", Year: 2000,
               tracks_attributes: [{ Song: "A", Seq: 1 }, { Song: "B", Seq: 2 }])

      txid = comp.versions.last.transaction_id
      assert txid.present?

      group = PaperTrail::Version.where(transaction_id: txid)
      assert_equal 3, group.count, "1 composition + 2 tracks share the transaction"

      event = AuditEvent.find_by(transaction_id: txid)
      assert_not_nil event, "an audit_event row is created for the transaction"
      assert_equal "Composition", event.primary_item_type, "parent outranks child rows"
      assert_equal comp.id, event.primary_item_id
      assert_equal "create", event.event
      assert_equal 3, event.version_count
      assert_equal({ "create" => 2 }, event.summary["Track"])
    end
  end

  test "AuditActivity classifies created child rows as added" do
    with_versioning do
      comp = Composition.create!(Title: "ZZ Added Album",
               tracks_attributes: [{ Song: "A", Seq: 1 }, { Song: "B", Seq: 2 }])
      activity = AuditActivity.new(comp.versions.last.transaction_id)

      assert_equal "Composition", activity.primary_version.item_type
      rows = activity.child_groups["Track"]
      assert_equal 2, rows.size
      assert(rows.all? { |row| row[:kind] == :added })
    end
  end

  test "AuditActivity classifies Seq-only track changes as reordered" do
    # Non-versioned setup, then a single versioned transaction.
    comp = Composition.create!(Title: "ZZ Reorder Album", Year: 1990,
             tracks_attributes: [{ Song: "A", Seq: 1 }, { Song: "B", Seq: 2 }])
    t1, t2 = comp.tracks.order(:Seq).to_a

    with_versioning do
      Composition.transaction do
        comp.update!(Year: 1991)
        t1.update!(Seq: 2)
        t2.update!(Seq: 1)
      end
    end

    activity = AuditActivity.new(comp.versions.last.transaction_id)
    assert_equal "Composition", activity.primary_version.item_type
    rows = activity.child_groups["Track"]
    assert_equal 2, rows.size
    assert(rows.all? { |row| row[:kind] == :reordered },
           "Seq-only changes should classify as reordered, got #{rows.map { |r| r[:kind] }.inspect}")
  end

  test "AuditActivity classifies a content change as changed" do
    comp = Composition.create!(Title: "ZZ Changed Album", Year: 1990,
             tracks_attributes: [{ Song: "A", Seq: 1 }])
    track = comp.tracks.first

    with_versioning do
      Composition.transaction do
        comp.update!(Year: 1991)
        track.update!(Song: "A (remastered)")
      end
    end

    activity = AuditActivity.new(comp.versions.last.transaction_id)
    rows = activity.child_groups["Track"]
    assert_equal 1, rows.size
    assert_equal :changed, rows.first[:kind]
  end

  test "a tracklist-only edit elevates the headline to the owning composition" do
    # Composition created without versioning; only the added track is audited, so
    # the transaction contains a Track row but no Composition row.
    comp = Composition.create!(Title: "ZZ Elevate Album", Year: 1995,
             tracks_attributes: [{ Song: "A", Seq: 1 }])

    with_versioning do
      comp.tracks.create!(Song: "B", Seq: 2)
    end

    version = comp.tracks.order(:Seq).last.versions.last
    event = AuditEvent.find_by(transaction_id: version.transaction_id)
    assert_not_nil event
    assert_equal "Composition", event.primary_item_type, "a child-only edit headlines the owning parent"
    assert_equal comp.id, event.primary_item_id
    assert_equal "ZZ Elevate Album (1995)", event.item_name
    assert_equal "update", event.event, "the parent was modified through its child, so the action is update"
    assert event.primary_elevated?

    activity = AuditActivity.new(version.transaction_id)
    assert_nil activity.primary_version, "no parent version exists in a child-only transaction"
    assert_empty activity.parent_changes
    assert_equal 1, activity.child_groups["Track"].size
    assert_equal :added, activity.child_groups["Track"].first[:kind]
  end

  test "removing a child row elevates via the destroyed row's owner" do
    # Exercises the destroy path: the Track row is gone by the time the version is
    # recorded, so its owner is resolved by reifying the version.
    comp = Composition.create!(Title: "ZZ Remove Album", Year: 1998,
             tracks_attributes: [{ Song: "A", Seq: 1 }, { Song: "B", Seq: 2 }])
    track = comp.tracks.order(:Seq).last

    with_versioning do
      track.destroy!
    end

    version = PaperTrail::Version.where(item_type: "Track", item_id: track.id, event: "destroy").last
    event = AuditEvent.find_by(transaction_id: version.transaction_id)
    assert_equal "Composition", event.primary_item_type, "a destroyed child still headlines its owning parent"
    assert_equal comp.id, event.primary_item_id
    assert_equal "update", event.event
    assert event.primary_elevated?
  end

  test "summary_text omits the primary item type" do
    with_versioning do
      comp = Composition.create!(Title: "ZZ Summary Album",
               tracks_attributes: [{ Song: "A", Seq: 1 }])
      event = AuditEvent.find_by(transaction_id: comp.versions.last.transaction_id)
      assert_equal "1 track", event.summary_text
    end
  end

  test "for_recent_updates excludes destroys and non-top-level types, newest first" do
    Rails.application.eager_load! # ensure every `audited` model has registered

    older = AuditEvent.create!(transaction_id: 900_001, primary_item_type: "Gig", primary_item_id: 1,
              item_name: "Old Gig", event: "create", created_at: 2.days.ago)
    newer = AuditEvent.create!(transaction_id: 900_002, primary_item_type: "Venue", primary_item_id: 2,
              item_name: "New Venue", event: "update", created_at: 1.day.ago)
    AuditEvent.create!(transaction_id: 900_003, primary_item_type: "Song", primary_item_id: 3,
      item_name: "Deleted Song", event: "destroy", created_at: 1.hour.ago)
    AuditEvent.create!(transaction_id: 900_004, primary_item_type: "Gigset", primary_item_id: 4,
      item_name: "Some Setlist Row", event: "update", created_at: 1.hour.ago)

    ids = AuditEvent.for_recent_updates.pluck(:transaction_id)
    assert_equal [newer.transaction_id, older.transaction_id],
                 ids & [900_001, 900_002, 900_003, 900_004]
  end

  test "for_recent_updates drops earlier events for an item that was later destroyed" do
    Rails.application.eager_load!

    # A gig created, edited, then deleted: the destroy row is filtered out, and these
    # two must go too or the feed links to a record that no longer exists.
    AuditEvent.create!(transaction_id: 900_201, primary_item_type: "Gig", primary_item_id: 77,
      item_name: "Doomed Gig", event: "create", created_at: 3.days.ago)
    AuditEvent.create!(transaction_id: 900_202, primary_item_type: "Gig", primary_item_id: 77,
      item_name: "Doomed Gig", event: "update", created_at: 2.days.ago)
    AuditEvent.create!(transaction_id: 900_203, primary_item_type: "Gig", primary_item_id: 77,
      item_name: "Doomed Gig", event: "destroy", created_at: 1.day.ago)

    # A different gig that is still alive, to prove the filter is not just excluding
    # everything, and that one item's deletion doesn't affect another's rows.
    survivor = AuditEvent.create!(transaction_id: 900_204, primary_item_type: "Gig", primary_item_id: 78,
      item_name: "Live Gig", event: "create", created_at: 2.days.ago)

    ids = AuditEvent.for_recent_updates.pluck(:transaction_id)
    assert_empty ids & [900_201, 900_202, 900_203],
                 "no event for a since-deleted item should reach the feed"
    assert_includes ids, survivor.transaction_id
  end

  test "for_recent_updates keeps events recorded after a destroy of the same id" do
    Rails.application.eager_load!

    # The legacy tables carry their own primary keys, so an id can be reissued. Only a
    # destroy *later* than the event should suppress it.
    AuditEvent.create!(transaction_id: 900_211, primary_item_type: "Venue", primary_item_id: 88,
      item_name: "Old Venue", event: "create", created_at: 5.days.ago)
    AuditEvent.create!(transaction_id: 900_212, primary_item_type: "Venue", primary_item_id: 88,
      item_name: "Old Venue", event: "destroy", created_at: 4.days.ago)
    reissued = AuditEvent.create!(transaction_id: 900_213, primary_item_type: "Venue", primary_item_id: 88,
      item_name: "New Venue On Reused Id", event: "create", created_at: 3.days.ago)

    ids = AuditEvent.for_recent_updates.pluck(:transaction_id)
    assert_not_includes ids, 900_211, "the pre-destroy event is suppressed"
    assert_includes ids, reissued.transaction_id, "the post-destroy event survives"
  end

  test "for_recent_updates ignores events older than RECENT_UPDATES_WINDOW" do
    Rails.application.eager_load!

    inside = AuditEvent.create!(transaction_id: 900_221, primary_item_type: "Song", primary_item_id: 91,
      item_name: "Recent Song", event: "update",
      created_at: AuditEvent::RECENT_UPDATES_WINDOW.ago + 1.day)
    AuditEvent.create!(transaction_id: 900_222, primary_item_type: "Song", primary_item_id: 92,
      item_name: "Ancient Song", event: "update",
      created_at: AuditEvent::RECENT_UPDATES_WINDOW.ago - 1.day)

    ids = AuditEvent.for_recent_updates.pluck(:transaction_id)
    assert_includes ids, inside.transaction_id, "an event inside the window is kept"
    assert_not_includes ids, 900_222, "an event older than the window is dropped"
  end

  test "for_recent_updates collapses same-day duplicate events for the same item" do
    Rails.application.eager_load!

    earlier_same_day = AuditEvent.create!(transaction_id: 900_005, primary_item_type: "Gig", primary_item_id: 42,
      item_name: "Dup Gig", event: "update", created_at: Time.zone.parse("2026-01-05 09:00"))
    later_same_day = AuditEvent.create!(transaction_id: 900_006, primary_item_type: "Gig", primary_item_id: 42,
      item_name: "Dup Gig", event: "update", created_at: Time.zone.parse("2026-01-05 17:00"))
    different_day = AuditEvent.create!(transaction_id: 900_007, primary_item_type: "Gig", primary_item_id: 42,
      item_name: "Dup Gig", event: "update", created_at: Time.zone.parse("2026-01-06 09:00"))
    different_event_same_day = AuditEvent.create!(transaction_id: 900_008, primary_item_type: "Gig", primary_item_id: 42,
      item_name: "Dup Gig", event: "create", created_at: Time.zone.parse("2026-01-05 09:30"))

    ids = AuditEvent.for_recent_updates.pluck(:transaction_id) &
          [900_005, 900_006, 900_007, 900_008]

    assert_not_includes ids, earlier_same_day.transaction_id,
                         "earlier same-day duplicate should be collapsed away"
    assert_includes ids, later_same_day.transaction_id,
                     "later same-day duplicate should be kept"
    assert_includes ids, different_day.transaction_id,
                     "a different day is not a duplicate"
    assert_includes ids, different_event_same_day.transaction_id,
                     "a different event type is not a duplicate"
  end
end
