class AddNameAndDescriptionToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :name, :string
    add_column :events, :description, :text
  end
end
