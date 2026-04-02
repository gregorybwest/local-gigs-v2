class SearchController < ApplicationController
  def index
    query = params[:q].to_s.strip
    return render json: [] if query.blank? || query.length < 2

    lat, lng, has_location = extract_location
    venues = venue_scope(query, lat, lng, has_location).limit(5).map { |v| venue_result(v, has_location) }
    events = event_scope(query, lat, lng, has_location).limit(5).map { |e| event_result(e) }

    render json: (venues + events).first(10)
  end

  def show
    @query = params[:q].to_s.strip
    lat, lng, has_location = extract_location

    if @query.length >= 2
      @events_pagy, @events = pagy(event_scope(@query, lat, lng, has_location), limit: 10, page_param: :events_page)
      @venues_pagy, @venues = pagy(venue_scope(@query, lat, lng, has_location), limit: 10, page_param: :venues_page)
    else
      @events_pagy = nil
      @events = Event.none
      @venues_pagy = nil
      @venues = Venue.none
    end
  end

  private

  def extract_location
    lat = params[:lat].presence&.to_f
    lng = params[:lng].presence&.to_f
    has_location = lat.present? && lng.present?
    [ lat, lng, has_location ]
  end

  def venue_scope(query, lat, lng, has_location)
    scope = Venue.where('name ILIKE ?', "%#{query}%")

    if has_location
      scope
        .select("venues.*, ST_Distance(coordinates, ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography) AS distance")
        .order(Arel.sql('distance ASC'))
    else
      scope.order(:name)
    end
  end

  def event_scope(query, lat, lng, has_location)
    scope = Event.where('events.name ILIKE ?', "%#{query}%")
                 .where('show_time > ?', Time.current)
                 .includes(:venue)

    if has_location
      scope
        .joins('LEFT JOIN venues ON venues.id = events.venue_id')
        .select("events.*, ST_Distance(venues.coordinates, ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography) AS distance")
        .order(Arel.sql('distance ASC NULLS LAST, show_time ASC'))
    else
      scope.order(show_time: :asc)
    end
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
