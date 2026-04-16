class EventsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events
  def index
    @events = Event.includes(:venue).where("show_time > ?", Time.current).order(show_time: :asc)
  end

  # GET /events/1
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  def create
    @event = current_user.events.build(event_params)
    @event.image = params[:event][:image] if params.dig(:event, :image).present?

    if @event.valid? && upload_image(@event) && @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /events/1
  def update
    @event.assign_attributes(event_params)
    @event.image = params[:event][:image] if params.dig(:event, :image).present?

    if @event.valid? && upload_image(@event) && @event.save
      redirect_to @event, notice: "Event was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /events/1
  def destroy
    @event.destroy!
    redirect_to events_path, notice: "Event was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.expect(event: [ :mapbox_id, :show_time, :ticket_link_url, :user_id, :name, :description, :venue_id ])
    end

    def upload_image(event)
      return true unless event.image.present?

      result = Cloudinary::Uploader.upload(event.image.tempfile.path, folder: "local_gigs/events")
      event.image_public_id = result["public_id"]
      true
    rescue StandardError => e
      Rails.logger.error("Cloudinary upload failed: #{e.class} - #{e.message}")
      event.errors.add(:image, "upload failed, please try again")
      false
    end
end
