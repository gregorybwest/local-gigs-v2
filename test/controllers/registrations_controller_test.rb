require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_user_params
    {
      email: "newuser@example.com",
      password: "securepass",
      password_confirmation: "securepass",
      preferred_location: "Chicago"
    }
  end

  # --- GET /signup ---

  test "GET /signup renders the registration form" do
    get signup_path
    assert_response :success
  end

  # --- POST /signup ---

  test "POST /signup with valid params creates user, sets session, and redirects" do
    assert_difference "User.count", 1, "A new user should be created on successful signup" do
      post signup_path, params: { user: valid_user_params }
    end

    assert_redirected_to root_path,
      "Successful signup should redirect to root"
    new_user = User.find_by(email: "newuser@example.com")
    assert_not_nil new_user, "The newly created user should exist in the database"
    assert_equal new_user.id, session[:user_id],
      "session[:user_id] should be set to the new user's id after signup"
  end

  test "POST /signup with missing email re-renders form with 422" do
    assert_no_difference "User.count", "No user should be created when email is missing" do
      post signup_path, params: { user: valid_user_params.merge(email: "") }
    end

    assert_response :unprocessable_entity
    assert_nil session[:user_id],
      "session[:user_id] should NOT be set when signup fails"
  end

  test "POST /signup with duplicate email re-renders form with 422" do
    User.create!(valid_user_params.except(:password_confirmation))

    assert_no_difference "User.count", "No second user should be created with a duplicate email" do
      post signup_path, params: { user: valid_user_params }
    end

    assert_response :unprocessable_entity,
      "Duplicate email on signup should respond with 422"
  end

  test "POST /signup with password confirmation mismatch re-renders form with 422" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: valid_user_params.merge(password_confirmation: "differentpassword")
      }
    end

    assert_response :unprocessable_entity,
      "Password confirmation mismatch should respond with 422"
  end

  test "POST /signup with missing preferred_location re-renders form with 422" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: valid_user_params.merge(preferred_location: "")
      }
    end

    assert_response :unprocessable_entity,
      "Missing preferred_location should respond with 422"
  end

  test "POST /signup with invalid email format re-renders form with 422" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: valid_user_params.merge(email: "notanemail")
      }
    end

    assert_response :unprocessable_entity,
      "Invalid email format on signup should respond with 422"
  end
end
