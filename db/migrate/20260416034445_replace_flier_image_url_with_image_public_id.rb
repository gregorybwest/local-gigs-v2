class ReplaceFlierImageUrlWithImagePublicId < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :flier_image_url, :string
    add_column :events, :image_public_id, :string
  end
end
