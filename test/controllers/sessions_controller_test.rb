require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # New action (login page)
  test "should get new login page" do
    get login_path
    assert_response :success
    assert_select "form"  # Should have a login form
  end

  test "should get new via sessions path" do
    get new_session_path
    assert_response :success
  end

  # Create action (login)
  test "should create session with valid credentials" do
    user = create(:user, email: "test@example.com", password: "password123", password_confirmation: "password123")

    post sessions_path, params: { email: "test@example.com", password: "password123" }

    assert_redirected_to root_url
    assert_equal user.id, session[:user_id]
    assert_equal "Logged in!", flash[:notice]
  end

  test "should not create session with invalid email" do
    create(:user, email: "test@example.com", password: "password123", password_confirmation: "password123")

    post sessions_path, params: { email: "wrong@example.com", password: "password123" }

    assert_response :success  # Re-renders the login form
    assert_nil session[:user_id]
    assert_equal "Email or password is invalid", flash[:alert]
  end

  test "should not create session with invalid password" do
    create(:user, email: "test@example.com", password: "password123", password_confirmation: "password123")

    post sessions_path, params: { email: "test@example.com", password: "wrongpassword" }

    assert_response :success  # Re-renders the login form
    assert_nil session[:user_id]
    assert_equal "Email or password is invalid", flash[:alert]
  end

  test "should not create session with missing email" do
    post sessions_path, params: { email: "", password: "password123" }

    assert_response :success
    assert_nil session[:user_id]
    assert_equal "Email or password is invalid", flash[:alert]
  end

  test "should not create session with missing password" do
    create(:user, email: "test@example.com", password: "password123", password_confirmation: "password123")

    post sessions_path, params: { email: "test@example.com", password: "" }

    assert_response :success
    assert_nil session[:user_id]
    assert_equal "Email or password is invalid", flash[:alert]
  end

  # Destroy action (logout)
  test "should destroy session and logout user" do
    user = create(:user)
    # Simulate logged-in session
    post sessions_path, params: { email: user.email, password: "password123" }
    assert_equal user.id, session[:user_id]

    # Logout
    get logout_path

    assert_redirected_to root_url
    assert_nil session[:user_id]
    assert_equal "Logged out!", flash[:notice]
  end

  test "should handle logout when not logged in" do
    get logout_path

    assert_redirected_to root_url
    assert_nil session[:user_id]
    assert_equal "Logged out!", flash[:notice]
  end

  test "should destroy session via delete request" do
    user = create(:user)
    post sessions_path, params: { email: user.email, password: "password123" }

    delete session_path(user.id)

    assert_redirected_to root_url
    assert_nil session[:user_id]
  end
end
