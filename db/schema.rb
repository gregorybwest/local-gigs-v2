# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_15_041646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "flier_image_url"
    t.string "mapbox_id"
    t.string "name"
    t.datetime "show_time"
    t.string "ticket_link_url"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "image_url"
    t.boolean "is_artist", default: false, null: false
    t.string "password", null: false
    t.string "preferred_location", null: false
    t.string "spotify_link"
    t.datetime "updated_at", null: false
    t.string "user_name", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.geography "coordinates", limit: {srid: 4326, type: "st_point", geographic: true}
    t.datetime "created_at", null: false
    t.string "image_url"
    t.integer "mapbox_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["coordinates"], name: "index_venues_on_coordinates", using: :gist
  end
end
