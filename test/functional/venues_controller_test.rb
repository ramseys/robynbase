require 'test_helper'

class VenuesControllerTest < ActionController::TestCase

  # --- search-result navigation ---

  SEARCH_BACK = "/venues/index?direction=asc&search_type=city&search_value=london&sort=venue".freeze

  test "index search results link to show pages carrying the search" do
    london_venue("Brixton Academy")

    get :index, params: { search_type: "city", search_value: "london" }

    backs = search_backs_in_rows
    assert_equal 2, backs.size
    assert_equal [SEARCH_BACK], backs.uniq
  end

  test "show walks prev and next through the search result set" do
    other = london_venue("Brixton Academy")

    # sorted by name asc: Brixton Academy, then The Roundhouse (venue 1)
    get :show, params: { id: other.id, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_nil nav[:prev]
    assert_equal SEARCH_BACK, nav[:back]
    assert_equal "/venues/1?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:next]

    get :show, params: { id: 1, search_back: SEARCH_BACK }
    nav = rendered_search_nav

    assert_equal "/venues/#{other.id}?search_back=#{CGI.escape(SEARCH_BACK)}", nav[:prev]
    assert_nil nav[:next]
  end

  test "show reached without a search renders no navigation bar" do
    get :show, params: { id: 1 }

    assert_nil rendered_search_nav
  end

  test "a search_back for another controller is ignored" do
    get :show, params: { id: 1, search_back: "/gigs/index?search_type=venue&search_value=roundhouse&sort=date&direction=desc" }

    assert_nil rendered_search_nav
  end

  private

    # A second London venue, so a city search has a result set with an order to walk.
    # Created per test rather than in setup: only two of these tests want it, and the
    # others should not have to reason about an extra row they never asked for.
    def london_venue(name)
      Venue.create!(Name: name, City: "London", Country: "UK")
    end

end
