require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "artist@example.com", password: "password", preferred_location: "LA")
    @venue = Venue.create!(name: "The Roxy", address: "9009 Sunset Blvd", city: "West Hollywood", mapbox_id: "poi.roxy123")
  end

  def valid_event_attributes
    { user: @user, show_time: 1.day.from_now, name: "Test Event" }
  end

  # --- Validations ---

  test "valid event with venue saves successfully" do
    event = Event.new(valid_event_attributes.merge(venue: @venue))
    assert event.valid?, "Event should be valid: #{event.errors.full_messages}"
  end

  test "event can be saved with a venue_id" do
    event = Event.create!(valid_event_attributes.merge(venue_id: @venue.id))
    event.reload
    assert_equal @venue.id, event.venue_id, "venue_id should be persisted and match the associated venue"
    assert_equal @venue.name, event.venue.name
  end

  test "event can be saved without a venue" do
    event = Event.new(valid_event_attributes.merge(venue: nil))
    assert event.valid?, "Event should be valid without a venue: #{event.errors.full_messages}"
  end

  test "requires show_time" do
    event = Event.new(valid_event_attributes.merge(show_time: nil))
    assert_not event.valid?, "Event without show_time should be invalid"
    assert_includes event.errors[:show_time], "can't be blank",
      "Expected a 'can't be blank' error on show_time"
  end

  test "requires user" do
    event = Event.new(valid_event_attributes.merge(user: nil, user_id: nil))
    assert_not event.valid?, "Event without a user should be invalid"
  end

  # --- Associations ---

  test "belongs_to venue association" do
    event = Event.create!(valid_event_attributes.merge(venue: @venue))
    assert_equal @venue, event.venue, "event.venue should return the associated venue"
  end

  test "venue is accessible through event" do
    event = Event.create!(valid_event_attributes.merge(venue: @venue))
    event.reload
    assert_equal "The Roxy", event.venue.name
    assert_equal "West Hollywood", event.venue.city
  end

  # --- upcoming? / past? ---

  test "upcoming? returns true for a future event" do
    event = Event.new(valid_event_attributes.merge(show_time: 1.hour.from_now))
    assert event.upcoming?, "An event 1 hour in the future should be upcoming"
  end

  test "upcoming? returns false for a past event" do
    event = Event.new(valid_event_attributes.merge(show_time: 1.hour.ago))
    assert_not event.upcoming?, "An event 1 hour in the past should not be upcoming"
  end

  test "past? returns true for a past event" do
    event = Event.new(valid_event_attributes.merge(show_time: 1.day.ago))
    assert event.past?, "An event in the past should return past? == true"
  end

  test "past? returns true when show_time equals current time (boundary)" do
    # show_time <= Time.current means present moment is considered past
    event = Event.new(valid_event_attributes.merge(show_time: Time.current))
    assert event.past?, "An event at exactly Time.current should be past? (boundary condition: <=)"
    assert_not event.upcoming?, "An event at exactly Time.current should not be upcoming? (boundary condition: >)"
  end

  # --- formatted_show_time ---

  test "formatted_show_time returns human-readable string" do
    show_time = Time.zone.local(2026, 6, 15, 20, 30, 0)
    event = Event.new(valid_event_attributes.merge(show_time: show_time))
    assert_equal "June 15, 2026 at 08:30 PM", event.formatted_show_time,
      "formatted_show_time should match the expected strftime pattern"
  end

  # --- venue_name ---

  test "venue_name returns the first segment of a comma-separated mapbox_id" do
    event = Event.new(valid_event_attributes.merge(mapbox_id: "The Roxy, West Hollywood, CA"))
    assert_equal "The Roxy", event.venue_name,
      "venue_name should return the first comma-separated segment of mapbox_id"
  end

  test "venue_name returns the full mapbox_id string when no comma present" do
    event = Event.new(valid_event_attributes.merge(mapbox_id: "TheRoxy"))
    assert_equal "TheRoxy", event.venue_name,
      "venue_name with no comma should return the full mapbox_id"
  end

  test "venue_name raises NoMethodError when mapbox_id is nil" do
    event = Event.new(valid_event_attributes.merge(mapbox_id: nil))
    error = assert_raises(NoMethodError) { event.venue_name }
    assert_match /split|NilClass/, error.message,
      "venue_name should raise NoMethodError when mapbox_id is nil (no nil guard)"
  end

  # --- upcoming scope ---

  test "upcoming scope returns only future events ordered by show_time ascending" do
    past_event   = Event.create!(valid_event_attributes.merge(show_time: 2.days.ago))
    near_future  = Event.create!(valid_event_attributes.merge(show_time: 1.hour.from_now))
    far_future   = Event.create!(valid_event_attributes.merge(show_time: 7.days.from_now))

    results = Event.upcoming
    assert_not_includes results, past_event,
      "upcoming scope should exclude events in the past"
    assert_includes results, near_future,
      "upcoming scope should include events in the near future"
    assert_includes results, far_future,
      "upcoming scope should include events in the far future"
    assert results.index(near_future) < results.index(far_future),
      "upcoming scope should order events by show_time ascending (soonest first)"
  end

  # --- Cascade deletion ---

  test "destroying a user destroys their events" do
    event = Event.create!(valid_event_attributes)
    event_id = event.id
    @user.destroy!
    assert_nil Event.find_by(id: event_id),
      "Events should be destroyed when their owning user is deleted (dependent: :destroy)"
  end
end
