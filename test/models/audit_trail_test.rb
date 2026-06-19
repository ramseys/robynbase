require 'test_helper'

# Basic PaperTrail behaviour for the tracked models.
class AuditTrailTest < ActiveSupport::TestCase

  test "creating a venue records a create version with item_name and changes" do
    with_versioning do
      venue = Venue.create!(Name: "Test Hall", City: "London", Country: "UK")
      version = venue.versions.last

      assert_equal "create", version.event
      assert_equal venue.audit_name, version.item_name
      assert version.object_changes.present?, "expected object_changes to be stored"
      assert version.transaction_id.present?, "expected a transaction_id"
    end
  end

  test "updating a song records an update version with a field diff" do
    with_versioning do
      song = Song.create!(Song: "Initial Name")
      song.update!(Song: "Renamed")
      version = song.versions.last

      assert_equal "update", version.event
      assert_equal ["Initial Name", "Renamed"], version.changeset["Song"]
    end
  end

  test "destroying a venue records a destroy version" do
    with_versioning do
      venue = Venue.create!(Name: "Temporary")
      id = venue.id
      venue.destroy!
      version = PaperTrail::Version.where(item_type: "Venue", item_id: id).last

      assert_equal "destroy", version.event
    end
  end

  test "whodunnit is stored from PaperTrail.request" do
    with_versioning do
      PaperTrail.request.whodunnit = "system:test"
      venue = Venue.create!(Name: "Attributed")
      assert_equal "system:test", venue.versions.last.whodunnit
    ensure
      PaperTrail.request.whodunnit = nil
    end
  end

  test "datetime and decimal field changes appear in the changeset" do
    # Regression: the YAML serializer dumped these as embedded Ruby objects that
    # safe_load rejected, blanking the whole changeset. JSON avoids that.
    with_versioning do
      venue = Venue.create!(Name: "Coords", latitude: 51.5)
      gig = Gig.create!(Venue: "Coords", venue: venue, GigDate: "1990-03-12")
      gig.update!(GigDate: "1991-06-01")
      assert gig.versions.last.changeset.key?("GigDate"), "datetime change should be recorded"

      venue.update!(latitude: 52.0)
      assert venue.versions.last.changeset.key?("latitude"), "decimal change should be recorded"
    end
  end

  test "Gig versions exclude the skipped ModifyDate column" do
    with_versioning do
      venue = Venue.create!(Name: "Venue For Gig")
      gig = Gig.create!(Venue: "Venue For Gig", venue: venue, GigYear: "1990")
      gig.update!(GigYear: "1991")
      version = gig.versions.last

      assert_equal "update", version.event
      assert_not version.changeset.key?("ModifyDate"), "ModifyDate should be skipped"
      assert version.changeset.key?("GigYear"), "real field change should be recorded"
    end
  end
end
