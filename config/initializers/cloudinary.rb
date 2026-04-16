Cloudinary.config do |config|
  config.cloud_name = Rails.application.credentials.dig(:cloudinary, :cloud_name) || ENV["CLOUDINARY_CLOUD_NAME"]
  config.api_key    = Rails.application.credentials.dig(:cloudinary, :api_key)    || ENV["CLOUDINARY_API_KEY"]
  config.api_secret = Rails.application.credentials.dig(:cloudinary, :api_secret) || ENV["CLOUDINARY_API_SECRET"]
  config.secure     = true
end
