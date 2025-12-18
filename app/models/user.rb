class User < ApplicationRecord
  has_many :events, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true
  validates :user_name, presence: true
  validates :preferred_location, presence: true
end
