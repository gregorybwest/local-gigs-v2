class VenuesController < ApplicationController
  skip_forgery_protection only: [ :create ]

  def index
    @venues = Venue.all
    render json: @venues.map { |v| venue_json(v, source: "local") }
  end

  def search
    query = params[:q]
    return render json: [] if query.blank?

    # First, search local database
    local_results = Venue.where("name ILIKE ?", "%#{query}%").limit(5)

    if local_results.any?
      render json: local_results.map { |v| venue_json(v, source: "local") }
    else
      # Fall back to Mapbox API
      mapbox_results = MapboxService.new.search(query)
      render json: mapbox_results.map { |r| r.merge(source: "mapbox") }
    end
  end

  def create
    venue = Venue.find_by(mapbox_id: venue_params[:mapbox_id])

    if venue
      render json: venue_json(venue, source: "local"), status: :ok
    else
      venue = Venue.new(venue_params)
      if venue.save
        render json: venue_json(venue, source: "local"), status: :created
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  private

  def venue_json(venue, source: "local")
    {
      id: venue.id,
      mapbox_id: venue.mapbox_id,
      name: venue.name,
      address: venue.address,
      city: venue.city,
      latitude: venue.latitude,
      longitude: venue.longitude,
      source: source
    }
  end

  def venue_params
    params.require(:venue).permit(:name, :address, :city, :mapbox_id, :latitude, :longitude, :image_url)
  end
end
