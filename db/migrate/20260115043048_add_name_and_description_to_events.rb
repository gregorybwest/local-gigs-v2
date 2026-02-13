class AddNameAndDescriptionToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :name, :string unless column_exists?(:events, :name)
    add_column :events, :description, :text unless column_exists?(:events, :description)
  end
end
