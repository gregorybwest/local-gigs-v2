require "net/http"
require "json"
require "uri"
require "openssl"

class MapboxService
  BASE_URL = "https://api.mapbox.com/search/searchbox/v1/forward"
  POI_CATEGORIES = "entertainment,music_venue,event_space,bar,pub"

  def initialize
    @access_token = Rails.application.credentials.mapbox[:access_token]
  end

  def search(query, limit: 5)
    return [] if query.blank?

    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(
      q: query,
      access_token: @access_token,
      limit: limit,
      country: "us",
      poi_category: POI_CATEGORIES,
      auto_complete: true
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5
    cert_store = OpenSSL::X509::Store.new
    cert_store.set_default_paths
    http.cert_store = cert_store

    response = http.request(Net::HTTP::Get.new(uri))
    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    parse_suggestions(data["features"] || [])
  rescue StandardError => e
    Rails.logger.error("MapboxService error: #{e.message}")
    []
  end

  private

  def parse_suggestions(features)
    features.map do |feature|
      properties = feature["properties"] || {}
      coordinates = feature.dig("geometry", "coordinates") || []
      context = properties["context"] || {}

      {
        mapbox_id: properties["mapbox_id"] || feature["id"],
        name: properties["name"],
        address: properties["full_address"] || properties["place_formatted"],
        city: context.dig("place", "name") || "",
        longitude: coordinates[0],
        latitude: coordinates[1]
      }
    end
  end
end
