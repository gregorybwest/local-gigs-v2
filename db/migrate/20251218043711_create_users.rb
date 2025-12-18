class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password, null: false
      t.string :user_name, null: false
      t.string :image_url
      t.boolean :is_artist, default: false, null: false
      t.string :spotify_link
      t.string :preferred_location, null: false
      t.text :bio

      t.timestamps
    end
    
    add_index :users, :email, unique: true
  end
end
