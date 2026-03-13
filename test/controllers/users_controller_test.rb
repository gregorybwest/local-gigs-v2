require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "profile@example.com",
      password: "password",
      preferred_location: "Seattle",
      bio: "I play guitar"
    )
    @other = User.create!(
      email: "other@example.com",
      password: "password",
      preferred_location: "Portland"
    )
  end

  def log_in_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  # --- GET /users ---

  test "GET /users lists all users" do
    get users_path
    assert_response :success,
      "GET /users should be accessible and return a success response"
  end

  # --- GET /users/:id ---

  test "GET /users/:id shows a user profile" do
    get user_path(@user)
    assert_response :success,
      "GET /users/:id should show the user's profile page"
  end

  test "GET /users/:id for non-existent user returns 404" do
    get user_path(id: 999_999)
    assert_response :not_found,
      "GET /users/:id for a non-existent user should return 404"
  end

  # --- PATCH /users/:id ---

  test "PATCH /users/:id updates user attributes and redirects" do
    log_in_as(@user)
    patch user_path(@user), params: {
      user: { bio: "Updated bio", preferred_location: "Denver" }
    }

    assert_redirected_to user_path(@user),
      "Successful user update should redirect to the user's profile"
    @user.reload
    assert_equal "Updated bio", @user.bio,
      "Bio should be updated in the database"
    assert_equal "Denver", @user.preferred_location,
      "preferred_location should be updated in the database"
  end

  test "PATCH /users/:id with invalid email re-renders form with 422" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { email: "bademail" } }

    assert_response :unprocessable_entity,
      "Updating a user with an invalid email should respond with 422"
  end

  test "PATCH /users/:id with duplicate email re-renders form with 422" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { email: @other.email } }

    assert_response :unprocessable_entity,
      "Updating a user with a duplicate email should respond with 422"
  end

  # --- DELETE /users/:id ---

  test "DELETE /users/:id destroys the user and redirects to users list" do
    log_in_as(@user)

    assert_difference "User.count", -1, "User should be removed from the database" do
      delete user_path(@user)
    end

    assert_redirected_to users_path,
      "Successful user deletion should redirect to /users"
  end

  test "DELETE /users/:id also destroys the user's events (dependent: :destroy)" do
    event = Event.create!(user: @user, show_time: 1.day.from_now, name: "My Show")
    event_id = event.id

    log_in_as(@user)
    delete user_path(@user)

    assert_nil Event.find_by(id: event_id),
      "Deleting a user should also delete their events (User has_many :events, dependent: :destroy)"
  end
end
