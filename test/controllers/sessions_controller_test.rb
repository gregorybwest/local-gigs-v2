require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "user@example.com",
      password: "correctpassword",
      preferred_location: "Los Angeles"
    )
  end

  # --- GET /login ---

  test "GET /login renders the login form" do
    get login_path
    assert_response :success
  end

  # --- POST /login ---

  test "POST /login with valid credentials sets session and redirects to root" do
    post login_path, params: { email: @user.email, password: "correctpassword" }

    assert_redirected_to root_path,
      "Successful login should redirect to root"
    assert_equal @user.id, session[:user_id],
      "session[:user_id] should be set to the logged-in user's id after successful login"
  end

  test "POST /login with wrong password re-renders form with 422" do
    post login_path, params: { email: @user.email, password: "wrongpassword" }

    assert_response :unprocessable_entity,
      "Login with wrong password should respond with 422"
    assert_nil session[:user_id],
      "session[:user_id] should NOT be set when password is wrong"
  end

  test "POST /login with non-existent email re-renders form with 422" do
    post login_path, params: { email: "nobody@example.com", password: "anything" }

    assert_response :unprocessable_entity,
      "Login with unknown email should respond with 422"
    assert_nil session[:user_id],
      "session[:user_id] should NOT be set when email does not exist"
  end

  test "POST /login with blank credentials re-renders form with 422" do
    post login_path, params: { email: "", password: "" }

    assert_response :unprocessable_entity,
      "Login with blank credentials should respond with 422"
    assert_nil session[:user_id],
      "session[:user_id] should NOT be set for blank credentials"
  end

  # --- DELETE /logout ---

  test "DELETE /logout clears the session and redirects to root" do
    # Log in first
    post login_path, params: { email: @user.email, password: "correctpassword" }
    assert_equal @user.id, session[:user_id], "Precondition: user should be logged in"

    delete logout_path

    assert_redirected_to root_path,
      "Logout should redirect to root"
    assert_nil session[:user_id],
      "session[:user_id] should be nil after logout"
  end

  test "DELETE /logout when not logged in still redirects to root" do
    delete logout_path
    assert_redirected_to root_path,
      "Logout should redirect to root even when no session is active"
  end
end
