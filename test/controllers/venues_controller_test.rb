require "test_helper"

class VenuesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @venue = Venue.create!(
      name: "The Fillmore",
      address: "1805 Geary Blvd",
      city: "San Francisco",
      mapbox_id: "poi.fillmore123"
    )
  end

  test "GET /venues/search with matching query returns local results" do
    get search_venues_path, params: { q: "Fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.any?, "Should return at least one result"
    assert_equal "local", body.first["source"]
    assert_equal "The Fillmore", body.first["name"]
  end

  test "GET /venues/search with blank query returns empty array" do
    get search_venues_path, params: { q: "" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body
  end

  test "POST /venues creates a new venue from Mapbox data" do
    assert_difference "Venue.count", 1 do
      post venues_path, params: {
        venue: {
          name: "The Roxy",
          address: "9009 Sunset Blvd",
          city: "West Hollywood",
          mapbox_id: "poi.roxy456",
          latitude: "34.0901",
          longitude: "-118.3868"
        }
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "The Roxy", body["name"]
    assert body["id"].present?, "Response should include venue id"
  end

  test "POST /venues returns existing venue if mapbox_id already exists" do
    assert_no_difference "Venue.count" do
      post venues_path, params: {
        venue: {
          name: "The Fillmore",
          address: "1805 Geary Blvd",
          city: "San Francisco",
          mapbox_id: "poi.fillmore123"
        }
      }, as: :json
    end

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal @venue.id, body["id"]
  end

  test "POST /venues returns errors for invalid venue" do
    assert_no_difference "Venue.count" do
      post venues_path, params: {
        venue: {
          name: "",
          address: "",
          city: "",
          mapbox_id: ""
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["errors"].any?, "Should return validation errors"
  end

  # --- Extended: case-insensitive local search ---

  test "GET /venues/search is case-insensitive for local results" do
    get search_venues_path, params: { q: "fillmore" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.any?,
      "Search should be case-insensitive — 'fillmore' should match 'The Fillmore'"
    assert_equal "The Fillmore", body.first["name"]
  end

  test "GET /venues/search falls back to MapboxService when no local results match" do
    mapbox_result = {
      mapbox_id: "poi.mapbox_only",
      name: "Mapbox Venue",
      address: "99 Nowhere Rd",
      city: "Austin",
      longitude: -97.74,
      latitude: 30.27
    }

    # Stub MapboxService#search to avoid a live HTTP call
    mapbox_service_instance = MapboxService.allocate
    mapbox_service_instance.define_singleton_method(:search) { |_q, **_opts| [ mapbox_result ] }
    MapboxService.define_singleton_method(:new) { mapbox_service_instance }

    get search_venues_path, params: { q: "XYZNoLocalMatchPossible" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.any?,
      "When no local venues match, search should fall back to MapboxService results"
    assert_equal "mapbox", body.first["source"],
      "Fallback results should have source='mapbox'"
    assert_equal "Mapbox Venue", body.first["name"],
      "Fallback result name should match what MapboxService returned"
  ensure
    MapboxService.singleton_class.undef_method(:new) rescue nil
  end
end
