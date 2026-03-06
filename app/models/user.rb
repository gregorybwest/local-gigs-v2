class User < ApplicationRecord
  has_secure_password

  has_many :events, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :preferred_location, presence: true
end
