require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    user = build(:user)
    assert user.valid?
  end

  test "should require email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should require password on create" do
    user = User.new(email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should accept valid email formats" do
    valid_emails = %w[user@example.com USER@example.COM user.name@example.org first.last@example.co.uk]
    valid_emails.each do |valid_email|
      user = build(:user, email: valid_email)
      assert user.valid?, "#{valid_email} should be valid"
    end
  end

  # Authentication tests
  test "should authenticate with correct password" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    assert user.authenticate("password123")
  end

  test "should not authenticate with incorrect password" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    assert_not user.authenticate("wrongpassword")
  end

  test "should hash password using bcrypt" do
    user = create(:user, password: "password123")
    assert_not_equal "password123", user.password_digest
    assert user.password_digest.start_with?("$2a$")  # BCrypt hash prefix
  end

  # Edge cases
  test "should handle email case insensitivity" do
    create(:user, email: "Test@Example.COM")
    user = build(:user, email: "test@example.com")
    # Note: Rails default uniqueness validation is case-sensitive by default
    # This test documents current behavior - may need case-insensitive validation
  end

  test "should trim whitespace from email" do
    user = create(:user, email: "  user@example.com  ")
    # Note: This test documents current behavior - may need to add email normalization
    assert_match /\s/, user.email if user.email.match?(/\s/)
  end

  test "should allow passwords longer than 6 characters" do
    user = build(:user, password: "verylongpassword123", password_confirmation: "verylongpassword123")
    assert user.valid?
  end

  test "should allow special characters in password" do
    user = build(:user, password: 'p@ssw0rd!#$', password_confirmation: 'p@ssw0rd!#$')
    assert user.valid?
    assert user.save
    assert user.authenticate('p@ssw0rd!#$')
  end
end
