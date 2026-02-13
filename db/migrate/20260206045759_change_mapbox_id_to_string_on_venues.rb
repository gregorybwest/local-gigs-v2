class ChangeMapboxIdToStringOnVenues < ActiveRecord::Migration[8.1]
  def change
    change_column :venues, :mapbox_id, :string
  end
end
