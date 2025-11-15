require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  # Note: This controller has create/update/destroy commented out
  # Tests focus on read-only operations that are currently active

  # Index action
  test "should get index" do
    user1 = create(:user, email: "alice@example.com")
    user2 = create(:user, email: "bob@example.com")

    get users_url
    assert_response :success
  end

  test "index should list all users" do
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    get users_url
    assert_response :success
    # Would need controller-level test to verify @users assignment
  end

  # Show action
  test "should show user" do
    user = create(:user, email: "test@example.com")

    get user_url(user)
    assert_response :success
  end

  test "should handle non-existent user on show" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get user_url(id: 999999)
    end
  end

  # New action
  test "should get new user form" do
    get new_user_url
    assert_response :success
  end

  # Edit action
  test "should get edit user form" do
    user = create(:user)

    get edit_user_url(user)
    assert_response :success
  end

  test "should handle non-existent user on edit" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get edit_user_url(id: 999999)
    end
  end

  # Note: The following actions are currently commented out in the controller
  # When they are re-enabled, uncomment and adapt these tests:

  # test "should create user" do
  #   assert_difference('User.count') do
  #     post users_url, params: {
  #       user: {
  #         email: "new@example.com",
  #         password: "password123",
  #         password_confirmation: "password123",
  #         first_name: "John",
  #         last_name: "Doe"
  #       }
  #     }
  #   end
  #   assert_redirected_to user_url(User.last)
  # end
  #
  # test "should not create user with invalid email" do
  #   assert_no_difference('User.count') do
  #     post users_url, params: { user: { email: "invalid", password: "password123" } }
  #   end
  # end
  #
  # test "should update user" do
  #   user = create(:user)
  #   patch user_url(user), params: { user: { email: "updated@example.com" } }
  #   user.reload
  #   assert_equal "updated@example.com", user.email
  # end
  #
  # test "should destroy user" do
  #   user = create(:user)
  #   assert_difference('User.count', -1) do
  #     delete user_url(user)
  #   end
  #   assert_redirected_to users_url
  # end
end
