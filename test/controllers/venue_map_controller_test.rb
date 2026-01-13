require "test_helper"

class VenueMapControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get map_index_url
    assert_response :success
  end
end
