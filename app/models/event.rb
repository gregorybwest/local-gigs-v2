class Event < ApplicationRecord
  belongs_to :user
  belongs_to :venue, optional: true

  attr_accessor :image

  validates :show_time, presence: true
  validates :user_id, presence: true
  validates :name, presence: true
  validate :validate_image, if: -> { image.present? }

  scope :upcoming, -> { where("show_time > ?", Time.current).order(show_time: :asc) }

  def upcoming?
    show_time > Time.current
  end

  def past?
    show_time <= Time.current
  end

  def formatted_show_time
    show_time.strftime("%B %d, %Y at %I:%M %p")
  end

  def venue_name
    mapbox_id.split(",").first.strip
  end

  def image_url(width: 400, height: 300, crop: :fill)
    return nil unless image_public_id.present?

    Cloudinary::Utils.cloudinary_url(image_public_id, width: width, height: height, crop: crop, quality: "auto", fetch_format: "auto")
  end

  private

  def validate_image
    unless image.content_type.in?(%w[image/jpeg image/png])
      errors.add(:image, "must be a JPEG or PNG")
    end

    if image.size > 1.megabyte
      errors.add(:image, "must be less than 1MB")
    end
  end
end
