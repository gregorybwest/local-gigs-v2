class Venue < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :coordinates, presence: true
  validates :mapbox_id, presence: true
end
