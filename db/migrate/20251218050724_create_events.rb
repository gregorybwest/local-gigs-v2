class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :mapbox_id
      t.datetime :show_time
      t.string :flier_image_url
      t.string :ticket_link_url
      t.integer :user_id

      t.timestamps
    end
  end
end
