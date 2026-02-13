class AddVenueToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :venue, null: true, foreign_key: true
  end
end
