require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_user_attributes
    {
      email: "user@example.com",
      password: "securepassword",
      preferred_location: "San Francisco"
    }
  end

  # --- Validations: email ---

  test "valid user saves successfully" do
    user = User.new(valid_user_attributes)
    assert user.valid?, "User with valid attributes should be valid: #{user.errors.full_messages}"
  end

  test "requires email" do
    user = User.new(valid_user_attributes.merge(email: nil))
    assert_not user.valid?, "User without email should be invalid"
    assert_includes user.errors[:email], "can't be blank",
      "Expected a 'can't be blank' error on email"
  end

  test "email must be unique" do
    User.create!(valid_user_attributes)
    duplicate = User.new(valid_user_attributes)
    assert_not duplicate.valid?, "User with a duplicate email should be invalid"
    assert_includes duplicate.errors[:email], "has already been taken",
      "Expected 'has already been taken' error on email for duplicate"
  end

  test "rejects invalid email format — missing @" do
    user = User.new(valid_user_attributes.merge(email: "notanemail"))
    assert_not user.valid?, "Email 'notanemail' should be invalid"
    assert user.errors[:email].any?, "Expected email format error: #{user.errors[:email]}"
  end

  test "rejects invalid email format — missing domain" do
    user = User.new(valid_user_attributes.merge(email: "user@"))
    assert_not user.valid?, "Email 'user@' should be invalid"
    assert user.errors[:email].any?, "Expected email format error for 'user@'"
  end

  test "rejects invalid email format — missing local part" do
    user = User.new(valid_user_attributes.merge(email: "@example.com"))
    assert_not user.valid?, "Email '@example.com' should be invalid"
    assert user.errors[:email].any?, "Expected email format error for '@example.com'"
  end

  test "accepts a valid email with subdomain" do
    user = User.new(valid_user_attributes.merge(email: "user@mail.example.co.uk"))
    assert user.valid?, "Email with subdomain should be valid: #{user.errors.full_messages}"
  end

  # --- Validations: preferred_location ---

  test "requires preferred_location" do
    user = User.new(valid_user_attributes.merge(preferred_location: nil))
    assert_not user.valid?, "User without preferred_location should be invalid"
    assert_includes user.errors[:preferred_location], "can't be blank",
      "Expected a 'can't be blank' error on preferred_location"
  end

  # --- Authentication ---

  test "authenticate returns user with correct password" do
    user = User.create!(valid_user_attributes)
    assert user.authenticate("securepassword"),
      "authenticate should return a truthy value for the correct password"
  end

  test "authenticate returns false with incorrect password" do
    user = User.create!(valid_user_attributes)
    assert_equal false, user.authenticate("wrongpassword"),
      "authenticate should return false for an incorrect password"
  end

  test "password is stored as a digest, not plaintext" do
    user = User.create!(valid_user_attributes)
    assert_not_equal "securepassword", user.password_digest,
      "password_digest should be a bcrypt hash, not the plaintext password"
    assert user.password_digest.start_with?("$2a$"), "password_digest should be a bcrypt hash"
  end

  # --- Associations ---

  test "has_many events association" do
    user = User.create!(valid_user_attributes)
    assert_respond_to user, :events,
      "User should respond to :events"
  end

  test "destroying a user destroys their events (dependent: :destroy)" do
    user = User.create!(valid_user_attributes)
    event = Event.create!(user: user, show_time: 1.day.from_now)
    event_id = event.id

    user.destroy!

    assert_nil Event.find_by(id: event_id),
      "Events belonging to a destroyed user should also be destroyed (dependent: :destroy)"
  end

  # --- Defaults ---

  test "is_artist defaults to false" do
    user = User.create!(valid_user_attributes)
    assert_equal false, user.is_artist,
      "is_artist should default to false for new users"
  end
end
