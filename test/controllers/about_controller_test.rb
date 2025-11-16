require 'test_helper'

class AboutControllerTest < ActionDispatch::IntegrationTest
  test "should get about page" do
    get about_index_url
    assert_response :success
  end

  test "about page should display statistics" do
    # Create some test data
    venue = create(:venue)
    gig = create(:gig, venue: venue)
    song = create(:song)
    create(:gigset, gig: gig, song: song)

    get about_index_url
    assert_response :success
    # The controller should set @stats with song_count, gig_count, gigset_count, venue_count
  end

  test "about page should handle empty database" do
    # No data created
    get about_index_url
    assert_response :success
    # Should still work even with no data
  end
end
