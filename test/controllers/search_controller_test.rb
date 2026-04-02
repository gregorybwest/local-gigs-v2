require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  def setup
    @venue1 = Venue.create!(
      name: "The Fillmore",
      address: "1805 Geary Blvd",
      city: "San Francisco",
      mapbox_id: "poi.fillmore123",
      latitude: 37.7842,
      longitude: -122.4330
    )

    @venue2 = Venue.create!(
      name: "The Roxy",
      address: "9009 Sunset Blvd",
      city: "West Hollywood",
      mapbox_id: "poi.roxy456",
      latitude: 34.0901,
      longitude: -118.3868
    )

    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      preferred_location: "San Francisco"
    )

    @upcoming_event = Event.create!(
      name: "Jazz Night at Fillmore",
      show_time: 3.days.from_now,
      user: @user,
      venue: @venue1
    )

    @soon_event = Event.create!(
      name: "Rock Show at Fillmore",
      show_time: 1.day.from_now,
      user: @user,
      venue: @venue1
    )

    @past_event = Event.create!(
      name: "Blues at Fillmore",
      show_time: 1.day.ago,
      user: @user,
      venue: @venue1
    )

    @event_no_venue = Event.create!(
      name: "Jazz Jam Session",
      show_time: 2.days.from_now,
      user: @user,
      venue: nil
    )
  end

  # --- Blank / short query ---

  test "GET /search with blank query returns empty array" do
    get search_path, params: { q: "" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body, "Blank query should return no results"
  end

  test "GET /search with single character returns empty array" do
    get search_path, params: { q: "J" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body, "Single-character query should return no results"
  end

  # --- Event search ---

  test "GET /search returns matching events" do
    get search_path, params: { q: "Jazz" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_results = body.select { |r| r["type"] == "event" }
    assert event_results.any?, "Should return event results matching 'Jazz'"
    assert event_results.all? { |r| r["name"].include?("Jazz") },
      "All event results should match the query"
  end

  test "GET /search excludes past events" do
    get search_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_results = body.select { |r| r["type"] == "event" }
    event_names = event_results.map { |r| r["name"] }

    assert_not_includes event_names, "Blues at Fillmore",
      "Past events should be excluded from search results"
  end

  test "GET /search event results include expected fields" do
    get search_path, params: { q: "Jazz Night" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_result = body.find { |r| r["type"] == "event" && r["name"] == "Jazz Night at Fillmore" }
    assert event_result, "Should find the Jazz Night event"
    assert_equal "event", event_result["type"]
    assert event_result["id"].present?, "Should include event id"
    assert event_result["url"].present?, "Should include event url"
    assert event_result["show_time"].present?, "Should include formatted show time"
    assert_equal "The Fillmore", event_result["venue_name"],
      "Should include the venue name"
  end

  # --- Venue search ---

  test "GET /search returns matching venues" do
    get search_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    venue_results = body.select { |r| r["type"] == "venue" }
    assert venue_results.any?, "Should return venue results matching 'Fillmore'"
    assert_equal "The Fillmore", venue_results.first["name"]
  end

  test "GET /search venue results include expected fields" do
    get search_path, params: { q: "Roxy" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    venue_result = body.find { |r| r["type"] == "venue" }
    assert venue_result, "Should find a venue result"
    assert_equal "venue", venue_result["type"]
    assert venue_result["id"].present?, "Should include venue id"
    assert venue_result["url"].present?, "Should include venue url"
    assert_equal "9009 Sunset Blvd", venue_result["address"]
    assert_equal "West Hollywood", venue_result["city"]
  end

  # --- Mixed results ---

  test "GET /search returns both events and venues" do
    get search_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    types = body.map { |r| r["type"] }.uniq
    assert_includes types, "event", "Should return event results"
    assert_includes types, "venue", "Should return venue results"
  end

  test "GET /search limits to 10 total results" do
    get search_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    assert body.length <= 10, "Should return at most 10 total results"
  end

  # --- Case insensitivity ---

  test "GET /search is case-insensitive" do
    get search_path, params: { q: "jazz" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    assert body.any?, "Search should be case-insensitive"
  end

  # --- Ordering without location ---

  test "GET /search orders events by show_time when no location provided" do
    get search_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_results = body.select { |r| r["type"] == "event" }
    event_names = event_results.map { |r| r["name"] }

    rock_index = event_names.index("Rock Show at Fillmore")
    jazz_index = event_names.index("Jazz Night at Fillmore")

    if rock_index && jazz_index
      assert rock_index < jazz_index,
        "Soonest events should appear first when no location is provided"
    end
  end

  # --- Distance ordering ---

  test "GET /search orders venues by distance when location provided" do
    # Location near San Francisco (closer to Fillmore than Roxy)
    sf_lat = 37.7749
    sf_lng = -122.4194

    get search_path, params: { q: "The", lat: sf_lat, lng: sf_lng }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    venue_results = body.select { |r| r["type"] == "venue" }
    venue_names = venue_results.map { |r| r["name"] }

    fillmore_index = venue_names.index("The Fillmore")
    roxy_index = venue_names.index("The Roxy")

    if fillmore_index && roxy_index
      assert fillmore_index < roxy_index,
        "The Fillmore (SF) should appear before The Roxy (LA) when searching from SF"
    end
  end

  test "GET /search orders events by distance then show_time when location provided" do
    sf_lat = 37.7749
    sf_lng = -122.4194

    get search_path, params: { q: "Fillmore", lat: sf_lat, lng: sf_lng }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_results = body.select { |r| r["type"] == "event" }
    assert event_results.any?, "Should return event results with location params"
  end

  # --- Events without venue ---

  test "GET /search includes events without a venue" do
    get search_path, params: { q: "Jazz Jam" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)

    event_result = body.find { |r| r["type"] == "event" && r["name"] == "Jazz Jam Session" }
    assert event_result, "Should return events that have no venue"
    assert_nil event_result["venue_name"], "Venue name should be nil for venueless events"
  end
end
