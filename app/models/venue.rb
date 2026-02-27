class Venue < ApplicationRecord
  has_many :events, dependent: :nullify

  before_validation :set_coordinates_from_lat_lng

  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :mapbox_id, presence: true, uniqueness: true

  def latitude
    return @latitude_buffer if @latitude_buffer

    coord = coordinates
    return coord.y if coord.respond_to?(:y)
    return nil unless persisted?

    self.class.where(id: id).pick(Arel.sql("ST_Y(coordinates::geometry)"))
  end

  def longitude
    return @longitude_buffer if @longitude_buffer

    coord = coordinates
    return coord.x if coord.respond_to?(:x)
    return nil unless persisted?

    self.class.where(id: id).pick(Arel.sql("ST_X(coordinates::geometry)"))
  end

  def latitude=(value)
    @latitude_buffer = value.presence&.to_f
  end

  def longitude=(value)
    @longitude_buffer = value.presence&.to_f
  end

  private

  def set_coordinates_from_lat_lng
    lat = @latitude_buffer
    lng = @longitude_buffer
    return if lat.blank? || lng.blank?

    factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
    self.coordinates = factory.point(lng, lat)
  end
end
