namespace :dev do
  desc "Seed the database with development/testing data (venues, events, seed user)"
  task seed: :environment do
    load Rails.root.join("db/seeds/development.rb")
  end

  desc "Remove all events owned by the seed user (seed@localgigsapp.com)"
  task seed_clear: :environment do
    load Rails.root.join("db/seeds/clear_development.rb")
  end
end
