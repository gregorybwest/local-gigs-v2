require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "artist@example.com", password: "password", user_name: "artist1", preferred_location: "LA")
    @venue = Venue.create!(name: "The Roxy", address: "9009 Sunset Blvd", city: "West Hollywood", mapbox_id: "poi.roxy123")
  end

  def valid_event_attributes
    { user: @user, show_time: 1.day.from_now }
  end

  test "valid event with venue saves successfully" do
    event = Event.new(valid_event_attributes.merge(venue: @venue))
    assert event.valid?, "Event should be valid: #{event.errors.full_messages}"
  end

  test "event can be saved with a venue_id" do
    event = Event.create!(valid_event_attributes.merge(venue_id: @venue.id))
    event.reload
    assert_equal @venue.id, event.venue_id
    assert_equal @venue.name, event.venue.name
  end

  test "event can be saved without a venue" do
    event = Event.new(valid_event_attributes.merge(venue: nil))
    assert event.valid?, "Event should be valid without venue: #{event.errors.full_messages}"
  end

  test "requires show_time" do
    event = Event.new(valid_event_attributes.merge(show_time: nil))
    assert_not event.valid?
    assert_includes event.errors[:show_time], "can't be blank"
  end

  test "requires user" do
    event = Event.new(valid_event_attributes.merge(user: nil))
    assert_not event.valid?
  end

  test "belongs_to venue association" do
    event = Event.create!(valid_event_attributes.merge(venue: @venue))
    assert_equal @venue, event.venue
  end

  test "venue is accessible through event" do
    event = Event.create!(valid_event_attributes.merge(venue: @venue))
    event.reload
    assert_equal "The Roxy", event.venue.name
    assert_equal "West Hollywood", event.venue.city
  end
end
