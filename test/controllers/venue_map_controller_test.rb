require "test_helper"

class VenueMapControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get venue_index_url
    assert_response :success
  end
end
