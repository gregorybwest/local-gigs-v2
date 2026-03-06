class RemoveUserNameFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :user_name, :string
  end
end
