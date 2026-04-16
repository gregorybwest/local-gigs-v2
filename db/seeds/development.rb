# Development seed data — run via `rake dev:seed` or `rails runner db/seeds/development.rb`
#
# This script is idempotent: safe to re-run without creating duplicates.
# Requires Mapbox credentials to be configured (same as the rest of the app).
#
# What it creates:
#   - 1 seed artist user
#   - Up to 30 LA music venues (fetched from Mapbox if not already in the DB)
#   - 3 events per found/created venue, spread evenly over the next 90 days

puts "==> Starting development seed..."

# ---------------------------------------------------------------------------
# 1. Seed user
# ---------------------------------------------------------------------------
SEED_USER_EMAIL = "seed@localgigsapp.com"

seed_user = User.find_or_initialize_by(email: SEED_USER_EMAIL)
if seed_user.new_record?
  seed_user.assign_attributes(
    password: "SeedPassword1!",
    password_confirmation: "SeedPassword1!",
    preferred_location: "Los Angeles, CA",
    is_artist: true,
    bio: "Seed artist account for development testing."
  )
  seed_user.save!
  puts "    Created seed user: #{SEED_USER_EMAIL}"
else
  puts "    Seed user already exists: #{SEED_USER_EMAIL}"
end

# ---------------------------------------------------------------------------
# 2. Pre-defined LA venue candidates (order matters — first 30 found are used)
# ---------------------------------------------------------------------------
LA_VENUE_NAMES = [
  "The Troubadour",
  "The Roxy Theatre",
  "Whisky a Go Go",
  "The Viper Room",
  "El Rey Theatre",
  "The Wiltern",
  "Hollywood Bowl",
  "The Fonda Theatre",
  "Bardot Hollywood",
  "The Echo",
  "Echoplex",
  "The Lodge Room",
  "Teragram Ballroom",
  "Zebulon",
  "The Novo",
  "The Greek Theatre",
  "Shrine Auditorium",
  "The Mint",
  "Harvard & Stone",
  "The Hi Hat",
  "Resident DTLA",
  "Catch One",
  "Bootleg Theater",
  "Los Globos",
  "The Masonic Lodge at Hollywood Forever",
  "El Cid",
  "Café Nela",
  "1720 DTLA",
  "The Vista Theatre",
  "The Hollywood Palladium",
  # Backup candidates — used only if needed to reach 30 venues
  "House of Blues Hollywood",
  "The Belasco Theater",
  "Highland Park Bowl",
  "Gold-Diggers Hollywood",
  "The Hotel Cafe Hollywood",
  "El Floridita Hollywood",
  "Vermont Hollywood",
  "Cliftons Republic Los Angeles"
].freeze

MAX_VENUES = 30

# ---------------------------------------------------------------------------
# 3. Venue search helper
# ---------------------------------------------------------------------------

# Los Angeles metro area — proximity biases ranking, bbox hard-restricts results
LA_PROXIMITY = "-118.2437,34.0522"
LA_BBOX      = "-118.9510,33.7037,-117.6462,34.8233"

# ---------------------------------------------------------------------------
# 4. Find or fetch each venue (stop once MAX_VENUES are collected)
# ---------------------------------------------------------------------------
mapbox       = MapboxService.new
found_venues = []

LA_VENUE_NAMES.each do |venue_name|
  break if found_venues.size >= MAX_VENUES

  # Check DB by exact name first (case-insensitive) before hitting Mapbox
  existing = Venue.find_by("name ILIKE ?", venue_name)
  if existing
    puts "    Venue exists in DB: #{existing.name}"
    found_venues << existing
    next
  end

  results = mapbox.search(venue_name, proximity: LA_PROXIMITY, bbox: LA_BBOX)

  if results.blank?
    puts "    WARNING: No Mapbox result for '#{venue_name}' — skipping"
    next
  end

  best = results.first

  # Guard against mapbox_id already saved under a different name
  venue = Venue.find_by(mapbox_id: best[:mapbox_id])
  if venue
    puts "    Venue already in DB via mapbox_id: #{venue.name}"
    found_venues << venue
    next
  end

  venue = Venue.new(
    name:      best[:name],
    address:   best[:address],
    city:      best[:city].presence || "Los Angeles",
    mapbox_id: best[:mapbox_id],
    latitude:  best[:latitude],
    longitude: best[:longitude]
  )

  if venue.save
    puts "    Created venue: #{venue.name} (#{venue.city})"
    found_venues << venue
  else
    puts "    WARNING: Could not save '#{venue_name}': #{venue.errors.full_messages.join(', ')}"
  end
end

# Deduplicate in case two names resolved to the same DB record
found_venues = found_venues.uniq(&:id)
puts "    #{found_venues.size}/#{MAX_VENUES} venues ready."

# ---------------------------------------------------------------------------
# 5. Create events — 3 per venue, spread over the next 90 days
# ---------------------------------------------------------------------------
EVENTS_PER_VENUE  = 3
WINDOW_DAYS       = 90
START_OFFSET_DAYS = 7  # first event is at least 7 days from now

total_slots = found_venues.size * EVENTS_PER_VENUE
step_days   = (WINDOW_DAYS.to_f / total_slots).ceil

PLACEHOLDER_TICKET_URL = "https://example.com/tickets"

EVENT_TEMPLATES = [
  { name_suffix: "Night Show",      description: "An electrifying night of live music." },
  { name_suffix: "Late Night Set",  description: "A late night performance not to be missed." },
  { name_suffix: "Special Evening", description: "A special evening featuring local talent." }
].freeze

created_count  = 0
existing_count = 0

found_venues.each_with_index do |venue, venue_index|
  EVENTS_PER_VENUE.times do |event_index|
    slot_number = (venue_index * EVENTS_PER_VENUE) + event_index
    days_offset = START_OFFSET_DAYS + (slot_number * step_days)
    show_time   = days_offset.days.from_now.change(hour: 20, min: 0, sec: 0)

    template   = EVENT_TEMPLATES[event_index % EVENT_TEMPLATES.size]
    event_name = "#{venue.name} — #{template[:name_suffix]}"

    event = Event.find_or_initialize_by(
      name:     event_name,
      venue_id: venue.id,
      user_id:  seed_user.id
    )

    if event.new_record?
      event.assign_attributes(
        show_time:       show_time,
        description:     template[:description],
        ticket_link_url: PLACEHOLDER_TICKET_URL
      )
      event.save!
      created_count += 1
    else
      existing_count += 1
    end
  end
end

puts "    Created #{created_count} new events (#{existing_count} already existed)."
puts "==> Development seed complete."
