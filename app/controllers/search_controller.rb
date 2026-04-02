class SearchController < ApplicationController
  def index
    query = params[:q].to_s.strip
    return render json: [] if query.blank? || query.length < 2

    lat = params[:lat].presence&.to_f
    lng = params[:lng].presence&.to_f
    has_location = lat.present? && lng.present?

    venues = search_venues(query, lat, lng, has_location)
    events = search_events(query, lat, lng, has_location)

    results = (venues + events).first(10)
    render json: results
  end

  private

  def search_venues(query, lat, lng, has_location)
    scope = Venue.where('name ILIKE ?', "%#{query}%")

    if has_location
      scope = scope
        .select("venues.*, ST_Distance(coordinates, ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography) AS distance")
        .order(Arel.sql('distance ASC'))
    else
      scope = scope.order(:name)
    end

    scope.limit(5).map { |v| venue_result(v, has_location) }
  end

  def search_events(query, lat, lng, has_location)
    scope = Event.where('events.name ILIKE ?', "%#{query}%")
                 .where('show_time > ?', Time.current)
                 .includes(:venue)

    if has_location
      scope = scope
        .joins('LEFT JOIN venues ON venues.id = events.venue_id')
        .select("events.*, ST_Distance(venues.coordinates, ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography) AS distance")
        .order(Arel.sql('distance ASC NULLS LAST, show_time ASC'))
    else
      scope = scope.order(show_time: :asc)
    end

    scope.limit(5).map { |e| event_result(e) }
  end

  def venue_result(venue, has_location)
    {
      type: 'venue',
      id: venue.id,
      name: venue.name,
      address: venue.address,
      city: venue.city,
      url: venue_path(venue),
      distance: has_location && venue.respond_to?(:distance) ? venue.distance : nil
    }
  end

  def event_result(event)
    {
      type: 'event',
      id: event.id,
      name: event.name,
      show_time: event.formatted_show_time,
      show_time_iso: event.show_time.iso8601,
      venue_name: event.venue&.name,
      url: event_path(event)
    }
  end
end
