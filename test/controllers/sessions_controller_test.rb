require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should create session with invalid credentials" do
    post sessions_url, params: { email: 'wrong@example.com', password: 'wrong' }
    assert_response :success
  end

  test "should destroy session" do
    delete session_url(1)
    assert_redirected_to root_url
  end
end
