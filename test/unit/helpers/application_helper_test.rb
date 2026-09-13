require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  # --- with_search_back ---

  test "appends the search context to a show path" do
    search_back = "/songs/index?search_type=title&search_value=wasps&sort=name&direction=asc"

    assert_equal "/songs/1?search_back=#{CGI.escape(search_back)}", with_search_back("/songs/1", search_back)
  end

  test "escapes the search context so its own query string survives" do
    result = with_search_back("/gigs/1", "/gigs/index?search_type=venue&search_value=a b")

    assert_equal "/gigs/1?search_back=%2Fgigs%2Findex%3Fsearch_type%3Dvenue%26search_value%3Da+b", result
    assert_equal "/gigs/index?search_type=venue&search_value=a b", CGI.unescape(result.split("search_back=").last)
  end

  test "leaves the path alone when there is no search context" do
    assert_equal "/venues/1", with_search_back("/venues/1", nil)
    assert_equal "/venues/1", with_search_back("/venues/1", "")
  end

end
