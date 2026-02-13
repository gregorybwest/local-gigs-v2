class Venue < ApplicationRecord
  has_many :events, dependent: :nullify

  after_save :update_coordinates_from_lat_lng

  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :mapbox_id, presence: true, uniqueness: true

  def latitude
    @latitude_buffer || coordinates&.y
  end

  def longitude
    @longitude_buffer || coordinates&.x
  end

  def latitude=(value)
    @latitude_buffer = value.presence&.to_f
  end

  def longitude=(value)
    @longitude_buffer = value.presence&.to_f
  end

  private

  def update_coordinates_from_lat_lng
    lat = @latitude_buffer
    lng = @longitude_buffer
    return if lat.blank? || lng.blank?

    self.class.where(id: id).update_all(
      Arel.sql("coordinates = ST_SetSRID(ST_MakePoint(#{lng.to_f}, #{lat.to_f}), 4326)::geography")
    )
  end
end
