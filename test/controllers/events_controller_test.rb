require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @owner = User.create!(email: "owner@example.com", password: "password", preferred_location: "NYC")
    @other = User.create!(email: "other@example.com", password: "password", preferred_location: "LA")
    @event = Event.create!(user: @owner, show_time: 1.day.from_now, name: "Jazz Night")
  end

  def log_in_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  # --- Public actions (no login required) ---

  test "GET /events is accessible without login" do
    get events_path
    assert_response :success,
      "GET /events (index) should be publicly accessible"
  end

  test "GET /events/:id is accessible without login" do
    get event_path(@event)
    assert_response :success,
      "GET /events/:id (show) should be publicly accessible"
  end

  # --- Protected actions redirect when unauthenticated ---

  test "GET /events/new redirects to login when not logged in" do
    get new_event_path
    assert_redirected_to login_path,
      "Unauthenticated request to new event should redirect to login"
  end

  test "POST /events redirects to login when not logged in" do
    assert_no_difference "Event.count", "No event should be created by an unauthenticated request" do
      post events_path, params: { event: { show_time: 1.day.from_now, name: "Unauthorized" } }
    end
    assert_redirected_to login_path,
      "Unauthenticated POST to /events should redirect to login"
  end

  test "GET /events/:id/edit redirects to login when not logged in" do
    get edit_event_path(@event)
    assert_redirected_to login_path,
      "Unauthenticated request to edit event should redirect to login"
  end

  test "DELETE /events/:id redirects to login when not logged in" do
    assert_no_difference "Event.count", "No event should be destroyed by an unauthenticated request" do
      delete event_path(@event)
    end
    assert_redirected_to login_path,
      "Unauthenticated DELETE /events/:id should redirect to login"
  end

  # --- Authenticated create ---

  test "POST /events creates an event owned by current_user (not by user_id param)" do
    log_in_as(@owner)

    assert_difference "Event.count", 1, "A new event should be created" do
      post events_path, params: {
        event: {
          show_time: 2.days.from_now,
          name: "My Concert",
          user_id: @other.id  # should be ignored in favour of current_user
        }
      }
    end

    new_event = Event.order(:created_at).last
    assert_equal @owner.id, new_event.user_id,
      "Event owner should be current_user regardless of user_id param — " \
      "create uses current_user.events.build which sets user_id from the session"
    assert_redirected_to event_path(new_event)
  end

  test "POST /events with missing show_time re-renders form with 422" do
    log_in_as(@owner)

    assert_no_difference "Event.count", "No event should be created when show_time is missing" do
      post events_path, params: { event: { name: "No Time Event", show_time: "" } }
    end

    assert_response :unprocessable_entity,
      "Missing show_time should render the new form with 422"
  end

  # --- Authenticated update ---

  test "PATCH /events/:id updates the event and redirects" do
    log_in_as(@owner)
    patch event_path(@event), params: { event: { name: "Updated Name" } }

    assert_redirected_to event_path(@event),
      "Successful update should redirect to the event page"
    assert_equal "Updated Name", @event.reload.name,
      "Event name should be updated in the database"
  end

  # --- Authenticated destroy ---

  test "DELETE /events/:id destroys the event and redirects to index" do
    log_in_as(@owner)

    assert_difference "Event.count", -1, "Event should be removed from the database" do
      delete event_path(@event)
    end

    assert_redirected_to events_path,
      "Successful destroy should redirect to /events"
  end

  # --- Authorization gap (current behavior, not a fix) ---
  # NOTE: The application has no ownership check on edit/update/destroy.
  # Any logged-in user can currently modify any event.
  # These tests document that behavior so it is visible if access control is added later.

  test "PATCH /events/:id by a different logged-in user currently succeeds (no authorization check)" do
    log_in_as(@other)
    patch event_path(@event), params: { event: { name: "Hijacked Name" } }

    # Current behavior: succeeds with redirect (no ownership verification)
    assert_response :redirect,
      "Currently, any logged-in user can update any event — authorization is not enforced"
  end

  test "DELETE /events/:id by a different logged-in user currently succeeds (no authorization check)" do
    log_in_as(@other)

    assert_difference "Event.count", -1,
      "Currently, any logged-in user can destroy any event — authorization is not enforced" do
      delete event_path(@event)
    end
  end
end
