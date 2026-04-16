# Removes all events belonging to the seed user — run via `rake dev:seed_clear`
# or `rails runner db/seeds/clear_development.rb`
#
# Only destroys events owned by the seed user. Venues and the seed user are left intact.

SEED_USER_EMAIL = "seed@localgigsapp.com"

seed_user = User.find_by(email: SEED_USER_EMAIL)

unless seed_user
  puts "    Seed user (#{SEED_USER_EMAIL}) not found — nothing to clear."
  return
end

count = seed_user.events.count

if count.zero?
  puts "    No seed events found for #{SEED_USER_EMAIL}."
else
  seed_user.events.destroy_all
  puts "    Removed #{count} event(s) owned by #{SEED_USER_EMAIL}."
end

puts "==> Seed event cleanup complete."
