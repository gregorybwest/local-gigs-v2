class Event < ApplicationRecord
  belongs_to :user
  belongs_to :venue, optional: true

  validates :show_time, presence: true
  validates :user_id, presence: true

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
end
