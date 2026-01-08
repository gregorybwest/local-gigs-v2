class Venue < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
end
