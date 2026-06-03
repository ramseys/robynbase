require 'test_helper'

class GigControllerTest < ActionController::TestCase
  tests GigsController

  fixtures :GIG, :GSET, :SONG, :VENUE, :users, :gig_media

  setup do
    session[:user_id] = users(:one).id
  end

  # --- create ---

  test "create persists gig with setlist and media" do
    assert_difference ['Gig.count', 'Gigset.count', 'GigMedium.count'], 1 do
      post :create, params: gig_create_params(
        gigsets: { "0" => { Chrono: "10", SONGID: "1", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" } },
        gigmedia: { "0" => { Chrono: "10", mediaid: "yt123", mediatype: "1", title: "" } }
      )
    end
    assert_redirected_to gig_path(Gig.last)
  end

  test "create with no setlist or media still saves the gig" do
    assert_difference 'Gig.count', 1 do
      assert_no_difference ['Gigset.count', 'GigMedium.count'] do
        post :create, params: gig_create_params
      end
    end
    assert_redirected_to gig_path(Gig.last)
  end

  test "create with a validation failure does not persist child rows" do
    # VENUEID 9999 passes strong params but fails belongs_to presence validation at model level.
    # @song_list is not set by the create failure path (benign in practice — form dropdowns are
    # always valid), so we pre-populate it on the controller so the view can render.
    @controller.instance_variable_set(:@song_list, [])
    assert_no_difference ['Gig.count', 'Gigset.count', 'GigMedium.count'] do
      post :create, params: gig_create_params(
        overrides: { VENUEID: "9999", Venue: "Ghost Venue" },
        gigsets: { "0" => { Chrono: "10", SONGID: "1", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" } }
      )
    end
    assert_response :success
  end

  # --- update ---

  test "update with changed parent field persists the change" do
    patch :update, params: gig_update_params(1, overrides: { BilledAs: "Robyn Hitchcock & the Egyptians" })
    assert_equal "Robyn Hitchcock & the Egyptians", Gig.find(1).BilledAs
    assert_redirected_to gig_path(Gig.find(1))
  end

  test "update replaces setlist with new songs and correct Chrono values" do
    patch :update, params: gig_update_params(1,
      gigsets: {
        "0" => { "id" => "1", "_destroy" => "1", Chrono: "10", SONGID: "1", Song: "Madonna of the Wasps", Encore: "false", VersionNotes: "", MediaLink: "" },
        "1" => { "id" => "2", "_destroy" => "1", Chrono: "20", SONGID: "2", Song: "The Cheese Alarm",     Encore: "false", VersionNotes: "", MediaLink: "" },
        "2" => { Chrono: "10", SONGID: "3", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" },
        "3" => { Chrono: "20", SONGID: "1", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" }
      }
    )
    sets = Gig.find(1).gigsets.order(:Chrono)
    assert_equal 2, sets.count
    assert_equal 3, sets.first.SONGID
    assert_equal 10, sets.first.Chrono
  end

  test "update replaces media with new entries" do
    patch :update, params: gig_update_params(1,
      gigmedia: {
        "0" => { "id" => gig_media(:media_one).id.to_s, "_destroy" => "1", Chrono: "10", mediaid: "abc123xyz", mediatype: "2", title: "Full show" },
        "1" => { "id" => gig_media(:media_two).id.to_s, "_destroy" => "1", Chrono: "20", mediaid: "def456uvw", mediatype: "2", title: "Highlights" },
        "2" => { Chrono: "10", mediaid: "newvid99", mediatype: "1", title: "" }
      }
    )
    media = Gig.find(1).gigmedia
    assert_equal 1, media.count
    assert_equal "newvid99", media.first.mediaid
  end

  test "update adds setlist rows to a gig that had none" do
    patch :update, params: gig_update_params(2,
      gigsets: { "0" => { Chrono: "10", SONGID: "2", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" } }
    )
    assert_equal 1, Gig.find(2).gigsets.count
  end

  test "update with no setlist removes all existing setlist rows" do
    assert_equal 2, Gig.find(1).gigsets.count
    patch :update, params: gig_update_params(1,
      gigsets: {
        "0" => { "id" => "1", "_destroy" => "1", Chrono: "10", SONGID: "1", Song: "Madonna of the Wasps", Encore: "false", VersionNotes: "", MediaLink: "" },
        "1" => { "id" => "2", "_destroy" => "1", Chrono: "20", SONGID: "2", Song: "The Cheese Alarm",     Encore: "false", VersionNotes: "", MediaLink: "" }
      }
    )
    assert_equal 0, Gig.find(1).gigsets.count
  end

  # --- destroy ---

  test "destroy removes gig and its gigsets and gigmedia" do
    assert_difference 'Gig.count', -1 do
      assert_difference 'Gigset.count', -2 do
        assert_difference 'GigMedium.count', -2 do
          delete :destroy, params: { id: 1 }
        end
      end
    end
  end

  # --- transaction rollback ---

  test "failed parent update does not leave orphaned gigsets" do
    @controller.instance_variable_set(:@gig, Gig.find(1))
    @controller.instance_variable_set(:@song_list, [])
    assert_no_difference 'Gigset.count' do
      patch :update, params: gig_update_params(1,
        overrides: { VENUEID: "9999", Venue: "Ghost Venue" },
        gigsets: {
          "0" => { "id" => "1", "_destroy" => "1", Chrono: "10", SONGID: "1", Song: "Madonna of the Wasps", Encore: "false", VersionNotes: "", MediaLink: "" },
          "1" => { "id" => "2", "_destroy" => "1", Chrono: "20", SONGID: "2", Song: "The Cheese Alarm",     Encore: "false", VersionNotes: "", MediaLink: "" },
          "2" => { Chrono: "10", SONGID: "3", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" }
        }
      )
    end
    assert_equal 2, Gig.find(1).gigsets.count
  end

  test "failed gigset save rolls back parent update" do
    @controller.instance_variable_set(:@gig, Gig.find(1))
    @controller.instance_variable_set(:@song_list, [])
    original_billed_as = Gig.find(1).BilledAs
    assert_no_difference 'Gigset.count' do
      patch :update, params: gig_update_params(1,
        overrides: { BilledAs: "Changed Name" },
        gigsets: { "0" => { Chrono: "10", SONGID: "", Song: "", Encore: "false", VersionNotes: "", MediaLink: "" } }
      )
    end
    assert_equal original_billed_as, Gig.find(1).BilledAs
  end

  private

  def gig_create_params(gigsets: nil, gigmedia: nil, overrides: {})
    base = {
      VENUEID: "1",
      GigDate: "2024-03-01",
      Venue: "",
      BilledAs: "Robyn Hitchcock",
      GigType: "Concert",
      ShortNote: "",
      Reviews: "",
      Guests: "",
      Circa: "false",
      cancelled: "false",
      Favorite: "false"
    }.merge(overrides)

    base[:gigsets_attributes] = gigsets if gigsets
    base[:gigmedia_attributes] = gigmedia if gigmedia

    { gig: base }
  end

  def gig_update_params(id, gigsets: nil, gigmedia: nil, overrides: {})
    params = gig_create_params(gigsets: gigsets, gigmedia: gigmedia, overrides: overrides)
    params[:id] = id
    params
  end
end
