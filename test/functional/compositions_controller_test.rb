require 'test_helper'

class CompositionsControllerTest < ActionController::TestCase
  tests CompositionsController

  fixtures :COMP, :TRAK, :SONG, :users

  setup do
    session[:user_id] = users(:one).id
  end

  # --- create ---

  test "create persists composition with tracks" do
    assert_difference ['Composition.count', 'Track.count'], 1 do
      post :create, params: comp_create_params(
        tracks: { "0" => { Seq: "10", SONGID: "1", Song: "", VersionNotes: "", bonus: "false" } }
      )
    end
    assert_redirected_to composition_path(Composition.last)
  end

  test "create with no tracks still saves the composition" do
    assert_difference 'Composition.count', 1 do
      assert_no_difference 'Track.count' do
        post :create, params: comp_create_params
      end
    end
    assert_redirected_to composition_path(Composition.last)
  end

  test "create with a validation failure does not persist tracks" do
    # Strong params require Title/Artist so we can't blank them to trigger model failure.
    # Instead stub Composition.new to return a record whose save returns false, verifying
    # the controller only creates tracks after a successful parent save.
    @controller.instance_variable_set(:@song_list, [])
    failing_comp = Composition.new(Title: "Stub", Artist: "Stub")
    failing_comp.define_singleton_method(:save) { false }
    Composition.stub(:new, failing_comp) do
      assert_no_difference 'Track.count' do
        post :create, params: comp_create_params(
          tracks: { "0" => { Seq: "10", SONGID: "1", Song: "", VersionNotes: "", bonus: "false" } }
        )
      end
    end
    assert_response :success
  end

  # --- update ---

  test "update with changed parent field persists the change" do
    patch :update, params: comp_update_params(1, overrides: { Year: "1995" })
    assert_equal 1995, Composition.find(1).Year
    assert_redirected_to composition_path(Composition.find(1))
  end

  test "update replaces tracklist with new tracks and correct Seq values" do
    patch :update, params: comp_update_params(1,
      tracks: {
        "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
        "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" },
        "2" => { Seq: "10", SONGID: "3", Song: "", VersionNotes: "", bonus: "false" },
        "3" => { Seq: "20", SONGID: "2", Song: "", VersionNotes: "", bonus: "false" }
      }
    )
    tracks = Composition.find(1).tracks.order(:Seq)
    assert_equal 2, tracks.count
    assert_equal 3, tracks.first.SONGID
    assert_equal 10, tracks.first.Seq
  end

  test "update with no tracks removes all existing track rows" do
    assert_equal 2, Composition.find(1).tracks.count
    patch :update, params: comp_update_params(1,
      tracks: {
        "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
        "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" }
      }
    )
    assert_equal 0, Composition.find(1).tracks.count
  end

  # --- destroy ---

  test "destroy removes composition and its tracks" do
    assert_difference 'Composition.count', -1 do
      assert_difference 'Track.count', -2 do
        delete :destroy, params: { id: 1 }
      end
    end
  end

  # --- transaction rollback ---

  test "failed parent update does not leave orphaned tracks" do
    @controller.instance_variable_set(:@comp, Composition.find(1))
    @controller.instance_variable_set(:@song_list, [])
    comp = Composition.find(1)
    comp.define_singleton_method(:valid?) { |*| false }
    Composition.stub(:find, comp) do
      assert_no_difference 'Track.count' do
        patch :update, params: comp_update_params(1,
          overrides: { Year: "2099" },
          tracks: {
            "0" => { "id" => "1", "_destroy" => "1", Seq: "10", SONGID: "1", Song: "Madonna of the Wasps", VersionNotes: "", bonus: "false" },
            "1" => { "id" => "2", "_destroy" => "1", Seq: "20", SONGID: "2", Song: "The Cheese Alarm",     VersionNotes: "", bonus: "false" },
            "2" => { Seq: "10", SONGID: "3", Song: "", VersionNotes: "", bonus: "false" }
          }
        )
      end
    end
    assert_equal 2, Composition.find(1).tracks.count
  end

  test "failed track save rolls back parent update" do
    @controller.instance_variable_set(:@comp, Composition.find(1))
    @controller.instance_variable_set(:@song_list, [])
    original_year = Composition.find(1).Year
    assert_no_difference 'Track.count' do
      patch :update, params: comp_update_params(1,
        overrides: { Year: "2099" },
        tracks: { "0" => { Seq: "10", SONGID: "", Song: "", VersionNotes: "", bonus: "false" } }
      )
    end
    assert_equal original_year, Composition.find(1).Year
  end

  # --- search-result navigation ---

  SEARCH_BACK = "/compositions/index?direction=asc&search_type=title&sort=year".freeze

  test "index search results link to show pages carrying the search" do
    other = Composition.create!(Title: "Element of Light", Artist: "Robyn Hitchcock", Year: 1986, Type: "Album")

    get :index, params: { search_type: "title", search_value: "" }

    assert_equal [SEARCH_BACK], search_backs_in_rows.uniq

    # sorted by year asc: Element of Light (1986), then Perspex Island (1994)
    get :show, params: { id: other.id, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_equal "/compositions/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 1, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/compositions/#{other.id}?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_nil nav[:next]
  end

  test "a release-type-only search normalizes search_type and round-trips through replay" do
    other = Composition.create!(Title: "Element of Light", Artist: "Robyn Hitchcock", Year: 1986, Type: "Album")

    get :index, params: { release_type: ["0"] }
    search_back = search_backs_in_rows.first

    # the "all" that index substitutes for a blank search_type has to be captured, so
    # replay builds the same collection
    assert_equal "/compositions/index?direction=asc&release_type%5B%5D=0&search_type=all&sort=year", search_back

    get :show, params: { id: other.id, search_back: search_back }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal "/compositions/1?search_back=#{CGI.escape(search_back)}", nav[:next]
  end

  test "show reached without a search renders no navigation bar" do
    get :show, params: { id: 1 }

    assert_nil rendered_search_nav
  end

  test "for_resource rows never carry a search context" do
    get :for_resource, params: { resource_type: "song", resource_id: 1 }

    assert_includes @response.body, "row-link"
    assert_not_includes @response.body, "search_back"
  end

  test "a search_back for another controller is ignored" do
    get :show, params: { id: 1, search_back: "/songs/index?search_type=all&search_value=&sort=name&direction=asc" }

    assert_nil rendered_search_nav
  end

  private

  def comp_create_params(tracks: nil, overrides: {})
    base = {
      Title: "New Album",
      Artist: "Robyn Hitchcock",
      Year: "2024",
      Type: "Album",
      Comments: ""
    }.merge(overrides)

    base[:tracks_attributes] = tracks if tracks

    { composition: base }
  end

  def comp_update_params(id, tracks: nil, overrides: {})
    params = comp_create_params(tracks: tracks, overrides: overrides)
    params[:id] = id
    params
  end
end
