require 'test_helper'

class SongsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  # --- search-result navigation ---

  # sorted by name asc the three fixtures are Driving Aloud (3), Madonna of the Wasps (1),
  # The Cheese Alarm (2)
  SEARCH_BACK = "/songs/index?direction=asc&search_type=all&sort=name".freeze

  test "index search results link to show pages carrying the search" do
    get :index, params: { search_type: "all", search_value: "" }

    backs = search_backs_in_rows
    assert_equal 3, backs.size
    assert_equal [SEARCH_BACK], backs.uniq
  end

  test "show walks prev and next through the search result set" do
    get :show, params: { id: 3, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_equal "/songs/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 1, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/songs/3?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_equal "/songs/2?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 2, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/songs/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_nil nav[:next]
  end

  test "a record no longer matching the search keeps back but loses prev and next" do
    narrowed = "/songs/index?direction=asc&search_type=title&search_value=wasps&sort=name"

    get :show, params: { id: 2, search_back: narrowed }
    nav = rendered_search_nav

    assert_equal narrowed, nav[:back]
    assert_nil nav[:prev]
    assert_nil nav[:next]
  end

  test "show reached without a search renders no navigation bar" do
    get :show, params: { id: 1 }

    assert_nil rendered_search_nav
  end

  test "a search_back for another controller is ignored" do
    get :show, params: { id: 1, search_back: "/venues/index?search_type=city&search_value=london&sort=venue&direction=asc" }

    assert_nil rendered_search_nav
  end

  test "appended rows carry the same search as the listing" do
    assert_appended_rows_carry_the_listing_search(:index, search_type: "all", search_value: "")
  end

  # --- returning to the search after an edit ---

  test "an edit from a search returns to the show page carrying it" do
    session[:user_id] = users(:one).id

    assert_edit_round_trip_carries_search("/songs/1", SEARCH_BACK, song_update_params(1))
  end

  test "an edit without a search returns to the show page" do
    session[:user_id] = users(:one).id

    assert_edit_round_trip_without_search("/songs/1", song_update_params(1))
  end

  # --- create ---

  test "create goes to the new song's show page" do
    session[:user_id] = users(:one).id

    post :create, params: song_update_params(nil).except(:id)

    assert_redirected_to song_path(Song.last)
  end

  # --- failed saves re-render the form with the user's input ---

  test "create with a blank name re-renders the form with the entered values" do
    session[:user_id] = users(:one).id

    assert_no_difference 'Song.count' do
      post :create, params: { song: song_update_params(nil)[:song].merge(full_name: "", Author: "Robyn Hitchcock") }
    end

    assert_response :unprocessable_content
    assert_select "input[name='song[Author]'][value=?]", "Robyn Hitchcock"
    assert_select ".alert-danger li", "Name can't be blank"
    # the error is on :Song, but the full_name field that edits it is flagged
    assert_select "input[name='song[full_name]'].form-control.is-invalid"
    assert_select "input[name='song[Author]'].is-invalid", 0
  end

  test "update with a blank name re-renders the form instead of failing" do
    session[:user_id] = users(:one).id
    original_name = Song.find(1).full_name

    patch :update, params: song_update_params(1).deep_merge(song: { full_name: "", Author: "Changed Author" })

    assert_response :unprocessable_content
    assert_select "input[name='song[Author]'][value=?]", "Changed Author"
    assert_select ".alert-danger li", "Name can't be blank"
    assert_equal original_name, Song.find(1).full_name
  end

  private

    def song_update_params(id)
      { id: id, song: { full_name: "Madonna of the Wasps", Author: "", OrigBand: "", Lyrics: "", lyrics_ref: "", Comments: "" } }
    end

end
