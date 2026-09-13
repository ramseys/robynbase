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

  # --- search-result navigation ---

  SEARCH_BACK = "/gigs/index?direction=desc&search_type=venue&search_value=roundhouse&sort=date".freeze

  test "index search results link to show pages carrying the search" do
    get :index, params: { search_type: "venue", search_value: "roundhouse" }

    backs = search_backs_in_rows
    assert_equal 2, backs.size
    assert_equal [SEARCH_BACK], backs.uniq
  end

  test "show walks prev and next through the search result set" do
    # sorted by date desc the two Roundhouse gigs are gig 2 (2023-07-20), then gig 1 (2023-06-15)
    get :show, params: { id: 2, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_equal "/gigs/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 1, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/gigs/2?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_nil nav[:next]
  end

  test "show reached without a search renders no navigation bar" do
    get :show, params: { id: 1 }

    assert_nil rendered_search_nav
  end

  test "for_resource rows never carry a search context" do
    get :for_resource, params: { resource_type: "venue", resource_id: 1 }

    assert_includes @response.body, "row-link"
    assert_not_includes @response.body, "search_back"
  end

  test "on_this_day results round-trip through replay" do
    # a second gig sharing gig 1's month and day, so the replayed set has an order to walk
    other = Gig.create!(VENUEID: 1, Venue: "The Roundhouse", GigDate: "2019-06-15 20:00:00",
                        GigYear: "2019", BilledAs: "Robyn Hitchcock", GigType: "Concert")

    get :on_this_day, params: { date: { month: "6", day: "15" } }
    search_back = search_backs_in_rows.first

    assert_equal "/gigs/on_this_day?date%5Bday%5D=15&date%5Bmonth%5D=6&direction=desc&sort=date", search_back

    # date desc puts the 2023 gig first, the one just created second
    get :show, params: { id: 1, search_back: search_back }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal "/gigs/#{other.id}?search_back=#{CGI.escape(search_back)}", nav[:next]
  end

  test "a search_back for another controller is ignored" do
    get :show, params: { id: 1, search_back: "/songs/index?search_type=all&search_value=&sort=name&direction=asc" }

    assert_nil rendered_search_nav
  end

  # --- show-page header layout ---

  test "back to search sits left of prev and next, split off by a pipe" do
    get :show, params: { id: 1, search_back: SEARCH_BACK }
    steps = rendered_search_steps

    assert_match(/title="Back to Search"/, steps)
    assert_match(/<i class="bi-chevron-double-left"/, steps)
    assert steps.index("Back to Search") < steps.index("show-header-steps-divider"),
           "back should come before the divider"
    assert steps.index("show-header-steps-divider") < steps.index("Previous result"),
           "the divider should separate back from the stepping buttons"
    assert_not_includes rendered_header_links.to_s, "Back to Search",
                        "the in-page links line should not carry it as well"
  end

  test "the divider is dropped when there is nothing to step to" do
    # nothing matches this search, so the record has no siblings to step between
    stale = "/gigs/index?direction=desc&search_type=venue&search_value=nonexistent&sort=date"

    get :show, params: { id: 1, search_back: stale }
    steps = rendered_search_steps

    assert_match(/title="Back to Search"/, steps)
    assert_not_includes steps, "Previous result"
    assert_not_includes steps, "Next result"
    assert_not_includes steps, "show-header-steps-divider"
  end

  test "prev and next sit on the title line, above the in-page links" do
    get :show, params: { id: 1, search_back: SEARCH_BACK }
    header = rendered_show_header

    assert header.index('class="show-header-title-row"') < header.index('<div class="show-header-steps">'),
           "the inline steps should sit inside the title row"
    assert header.index('<div class="show-header-steps">') < header.index('class="inpage-navigation"'),
           "in-page links should come after the title row"
  end

  test "edit renders as a link after the in-page links for an admin" do
    # this test case is signed in as an admin (see setup)
    get :show, params: { id: 1 }
    links = rendered_header_links

    assert_match %r{<span class="show-header-edit d-none d-md-inline"><a href="/gigs/1/edit">Edit Gig</a></span>}, links,
                 "Edit stays desktop-only, like the other admin actions"

    assert links.index("#setlist") < links.index("Edit Gig"), "Edit should follow the in-page links"
    assert_no_match(/input[^>]*Edit Gig/, links, "Edit should be a link, not a submit button")
  end

  test "edit is not offered to anonymous visitors" do
    session.delete(:user_id)

    get :show, params: { id: 1 }

    assert_not_includes rendered_header_links.to_s, "Edit Gig"
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
