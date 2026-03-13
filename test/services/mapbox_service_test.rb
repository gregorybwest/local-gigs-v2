require "test_helper"

# MapboxService tests use stubbing to avoid live HTTP calls.
# The service is tested at two levels:
#   1. parse_suggestions (private) — exercised directly via `send`
#   2. search — HTTP layer stubbed with a lightweight response double
class MapboxServiceTest < ActiveSupport::TestCase
  def setup
    # Bypass MapboxService#initialize (which reads credentials) by allocating and
    # directly setting the instance variable to a dummy token.
    @service = MapboxService.allocate
    @service.instance_variable_set(:@access_token, "test_token")
  end

  # --- blank query guard ---

  test "search returns empty array for blank query" do
    result = @service.search("")
    assert_equal [], result, "search('') should return [] without making an HTTP request"
  end

  test "search returns empty array for nil query" do
    result = @service.search(nil)
    assert_equal [], result, "search(nil) should return [] without making an HTTP request"
  end

  test "search returns empty array for whitespace-only query" do
    result = @service.search("   ")
    assert_equal [], result, "search with only whitespace should return []"
  end

  # --- parse_suggestions (private) ---

  test "parse_suggestions maps a full feature correctly" do
    features = [
      {
        "properties" => {
          "mapbox_id"       => "poi.abc123",
          "name"            => "The Fillmore",
          "full_address"    => "1805 Geary Blvd, San Francisco, CA 94115",
          "context"         => { "place" => { "name" => "San Francisco" } }
        },
        "geometry" => { "coordinates" => [ -122.4320, 37.7841 ] }
      }
    ]

    results = @service.send(:parse_suggestions, features)

    assert_equal 1, results.length,
      "parse_suggestions should return one result per feature"
    r = results.first
    assert_equal "poi.abc123", r[:mapbox_id], "mapbox_id should come from properties"
    assert_equal "The Fillmore", r[:name]
    assert_equal "1805 Geary Blvd, San Francisco, CA 94115", r[:address],
      "address should prefer full_address"
    assert_equal "San Francisco", r[:city],
      "city should be extracted from context.place.name"
    assert_in_delta(-122.4320, r[:longitude], 0.0001)
    assert_in_delta(37.7841, r[:latitude], 0.0001)
  end

  test "parse_suggestions falls back to feature id when mapbox_id missing from properties" do
    features = [
      {
        "id"         => "fallback.id.456",
        "properties" => { "name" => "Some Venue" },
        "geometry"   => { "coordinates" => [ -118.0, 34.0 ] }
      }
    ]

    results = @service.send(:parse_suggestions, features)
    assert_equal "fallback.id.456", results.first[:mapbox_id],
      "mapbox_id should fall back to feature['id'] when not present in properties"
  end

  test "parse_suggestions falls back to place_formatted when full_address missing" do
    features = [
      {
        "properties" => {
          "mapbox_id"        => "poi.xyz",
          "name"             => "Jazz Club",
          "place_formatted"  => "456 Main St, Austin, TX"
        },
        "geometry" => { "coordinates" => [ -97.74, 30.27 ] }
      }
    ]

    results = @service.send(:parse_suggestions, features)
    assert_equal "456 Main St, Austin, TX", results.first[:address],
      "address should fall back to place_formatted when full_address is absent"
  end

  test "parse_suggestions returns empty city string when context is missing" do
    features = [
      {
        "properties" => { "mapbox_id" => "poi.no_context", "name" => "Venue" },
        "geometry"   => { "coordinates" => [ -90.0, 35.0 ] }
      }
    ]

    results = @service.send(:parse_suggestions, features)
    assert_equal "", results.first[:city],
      "city should be an empty string when context/place is absent"
  end

  test "parse_suggestions handles missing geometry coordinates gracefully" do
    features = [
      {
        "properties" => { "mapbox_id" => "poi.no_coords", "name" => "Ghost Venue" },
        "geometry"   => {}
      }
    ]

    results = @service.send(:parse_suggestions, features)
    assert_nil results.first[:longitude],
      "longitude should be nil when geometry.coordinates is absent"
    assert_nil results.first[:latitude],
      "latitude should be nil when geometry.coordinates is absent"
  end

  test "parse_suggestions returns empty array for empty feature list" do
    results = @service.send(:parse_suggestions, [])
    assert_equal [], results,
      "parse_suggestions should return [] when given no features"
  end

  # --- HTTP error handling (stub Net::HTTP) ---

  # Builds a minimal HTTP double that mimics a successful Net::HTTP response.
  # Temporarily patches Net::HTTP.new to return a fake HTTP object, then restores it.
  # This avoids real network calls and works without any mocking framework.
  def with_http_stub(fake_http)
    original_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*_| fake_http }
    yield
  ensure
    Net::HTTP.singleton_class.undef_method(:new)
    Net::HTTP.define_singleton_method(:new, original_new)
  end

  def build_stub_http_responding_with(response)
    fake_http = Object.new
    fake_http.define_singleton_method(:use_ssl=) { |_| }
    fake_http.define_singleton_method(:open_timeout=) { |_| }
    fake_http.define_singleton_method(:read_timeout=) { |_| }
    fake_http.define_singleton_method(:cert_store=) { |_| }
    fake_http.define_singleton_method(:request) { |_req| response }
    fake_http
  end

  def build_stub_http_raising(exception)
    fake_http = Object.new
    fake_http.define_singleton_method(:use_ssl=) { |_| }
    fake_http.define_singleton_method(:open_timeout=) { |_| }
    fake_http.define_singleton_method(:read_timeout=) { |_| }
    fake_http.define_singleton_method(:cert_store=) { |_| }
    fake_http.define_singleton_method(:request) { |_req| raise exception }
    fake_http
  end

  def fake_success_response(body_json)
    r = Object.new
    r.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess }
    r.define_singleton_method(:body) { body_json }
    r
  end

  def fake_failure_response
    r = Object.new
    r.define_singleton_method(:is_a?) { |_klass| false }
    r
  end

  test "search returns parsed venues on successful API response" do
    body = JSON.generate({
      "features" => [
        {
          "properties" => {
            "mapbox_id" => "poi.success",
            "name"      => "Live Music Venue",
            "full_address" => "100 Main St, Nashville, TN",
            "context"   => { "place" => { "name" => "Nashville" } }
          },
          "geometry" => { "coordinates" => [ -86.78, 36.16 ] }
        }
      ]
    })

    fake_http = build_stub_http_responding_with(fake_success_response(body))
    with_http_stub(fake_http) do
      results = @service.search("live music")
      assert_equal 1, results.length,
        "search should return one result matching the stubbed API response"
      assert_equal "Live Music Venue", results.first[:name]
      assert_equal "Nashville", results.first[:city]
    end
  end

  test "search returns empty array when API returns non-200 response" do
    fake_http = build_stub_http_responding_with(fake_failure_response)
    with_http_stub(fake_http) do
      result = @service.search("something")
      assert_equal [], result,
        "search should return [] when the HTTP response is not a success (non-200)"
    end
  end

  test "search returns empty array on network timeout" do
    fake_http = build_stub_http_raising(Net::OpenTimeout.new("timed out"))
    with_http_stub(fake_http) do
      result = @service.search("timeout test")
      assert_equal [], result,
        "search should rescue Net::OpenTimeout and return []"
    end
  end

  test "search returns empty array on generic network error" do
    fake_http = build_stub_http_raising(StandardError.new("connection refused"))
    with_http_stub(fake_http) do
      result = @service.search("error test")
      assert_equal [], result,
        "search should rescue any StandardError and return []"
    end
  end

  test "search returns empty array when API response body is malformed JSON" do
    fake_http = build_stub_http_responding_with(fake_success_response("NOT VALID JSON {{{{"))
    with_http_stub(fake_http) do
      result = @service.search("bad json")
      assert_equal [], result,
        "search should rescue JSON::ParserError (via StandardError) and return []"
    end
  end

  test "search returns empty array when features key is absent from response" do
    body = JSON.generate({ "type" => "FeatureCollection" })
    fake_http = build_stub_http_responding_with(fake_success_response(body))
    with_http_stub(fake_http) do
      result = @service.search("no features key")
      assert_equal [], result,
        "search should return [] when API response has no 'features' key"
    end
  end
end
