require 'test_helper'

class GigReorderAuditTest < ActionDispatch::IntegrationTest
  # A pure setlist reorder changes no GIG column, so the transaction is child-only
  # and the headline is elevated to the gig. GigYear/Venue are pre-set so
  # prepare_params does not dirty the gig (which would create a real Gig version).
  test "reordering a setlist through the controller creates an elevated audit_event" do
    venue = Venue.create!(Name: "ZZ Reorder Venue")
    gig = Gig.create!(GigDate: "1990-01-01", GigYear: 1990, Venue: "ZZ Reorder Venue", venue: venue)
    a = gig.gigsets.create!(Song: "A", Chrono: 10)
    b = gig.gigsets.create!(Song: "B", Chrono: 20)
    c = gig.gigsets.create!(Song: "C", Chrono: 30)

    post sessions_url, params: { email: users(:one).email, password: "secret" }

    assert_difference -> { AuditEvent.count }, 1 do
      with_versioning do
        patch gig_url(gig), params: {
          gig: {
            VENUEID: venue.id,
            GigDate: "1990-01-01",
            Venue: "ZZ Reorder Venue",
            gigsets_attributes: {
              "0" => { id: a.id, Chrono: 30, SONGID: 0, Song: "A", Encore: "false" },
              "1" => { id: b.id, Chrono: 10, SONGID: 0, Song: "B", Encore: "false" },
              "2" => { id: c.id, Chrono: 20, SONGID: 0, Song: "C", Encore: "false" }
            }
          }
        }
      end
    end

    assert_response :redirect
    assert_equal [["B", 10], ["C", 20], ["A", 30]], gig.gigsets.reload.order(:Chrono).pluck(:Song, :Chrono)

    event = AuditEvent.order(:id).last
    assert_equal "Gig", event.primary_item_type, "a setlist-only reorder headlines the gig"
    assert_equal gig.id, event.primary_item_id
    assert_equal "update", event.event
    assert event.primary_elevated?
    assert_equal "ZZ Reorder Venue - 1990-01-01", event.item_name
  end
end
