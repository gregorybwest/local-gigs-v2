class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    # Enable PostGIS extension (Supabase supports this)
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :venues do |t|
      t.string :name
      t.string :address
      t.string :city
      t.string :image_url
      t.integer :mapbox_id

      t.timestamps
    end

    # Add PostGIS geography column using raw SQL (works without postgis adapter)
    execute <<-SQL
      ALTER TABLE venues ADD COLUMN coordinates geography(Point, 4326);
    SQL

    add_index :venues, :coordinates, using: :gist
  end
end
