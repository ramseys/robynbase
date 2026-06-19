require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  tests AdminController

  fixtures :users

  test "requires login" do
    get :index
    assert_redirected_to login_path
  end

  test "index renders, including the recent audit table when activity exists" do
    session[:user_id] = users(:one).id
    with_versioning do
      Composition.create!(Title: "ZZ Admin Index Album",
        tracks_attributes: [{ Song: "A", Seq: 1 }])
    end
    get :index
    assert_response :success
  end

  test "index renders when there is no audit activity" do
    session[:user_id] = users(:one).id
    get :index
    assert_response :success
  end
end
