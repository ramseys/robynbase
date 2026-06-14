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
end
