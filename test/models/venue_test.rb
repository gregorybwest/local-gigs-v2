require "test_helper"

class VenueTest < ActiveSupport::TestCase
  def valid_venue_attributes
    {
      name: "The Fillmore",
      address: "1805 Geary Blvd",
      city: "San Francisco",
      mapbox_id: "poi.#{SecureRandom.hex(4)}"
    }
  end

  test "valid venue saves successfully" do
    venue = Venue.new(valid_venue_attributes)
    assert venue.valid?, "Venue should be valid: #{venue.errors.full_messages}"
  end

  test "requires name" do
    venue = Venue.new(valid_venue_attributes.merge(name: nil))
    assert_not venue.valid?
    assert_includes venue.errors[:name], "can't be blank"
  end

  test "requires address" do
    venue = Venue.new(valid_venue_attributes.merge(address: nil))
    assert_not venue.valid?
    assert_includes venue.errors[:address], "can't be blank"
  end

  test "requires city" do
    venue = Venue.new(valid_venue_attributes.merge(city: nil))
    assert_not venue.valid?
    assert_includes venue.errors[:city], "can't be blank"
  end

  test "requires mapbox_id" do
    venue = Venue.new(valid_venue_attributes.merge(mapbox_id: nil))
    assert_not venue.valid?
    assert_includes venue.errors[:mapbox_id], "can't be blank"
  end

  test "mapbox_id must be unique" do
    Venue.create!(valid_venue_attributes.merge(mapbox_id: "poi.unique123"))
    duplicate = Venue.new(valid_venue_attributes.merge(mapbox_id: "poi.unique123"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:mapbox_id], "has already been taken"
  end

  test "setting latitude and longitude creates coordinates" do
    venue = Venue.new(valid_venue_attributes.merge(latitude: 34.0522, longitude: -118.2437))
    venue.save!
    venue.reload

    assert_in_delta 34.0522, venue.latitude, 0.0001
    assert_in_delta(-118.2437, venue.longitude, 0.0001)
    assert_not_nil venue.coordinates
  end

  test "latitude and longitude can be set in any order" do
    venue = Venue.new(valid_venue_attributes)
    venue.longitude = -118.2437
    venue.latitude = 34.0522
    venue.save!
    venue.reload

    assert_in_delta 34.0522, venue.latitude, 0.0001
    assert_in_delta(-118.2437, venue.longitude, 0.0001)
  end

  test "latitude and longitude setters handle string values" do
    venue = Venue.new(valid_venue_attributes.merge(latitude: "34.0522", longitude: "-118.2437"))
    venue.save!
    venue.reload

    assert_in_delta 34.0522, venue.latitude, 0.0001
    assert_in_delta(-118.2437, venue.longitude, 0.0001)
  end

  test "has_many events association" do
    venue = Venue.create!(valid_venue_attributes)
    assert_respond_to venue, :events
  end

  test "nullifies events when destroyed" do
    venue = Venue.create!(valid_venue_attributes)
    user = User.create!(email: "test@example.com", password: "password", user_name: "tester", preferred_location: "LA")
    event = Event.create!(venue: venue, user: user, show_time: 1.day.from_now)

    venue.destroy!
    event.reload
    assert_nil event.venue_id
  end
end
