class AddImageColumnsToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :avatar_tmp, :string
    add_column :groups, :avatar_processing, :boolean
    add_column :groups, :background_image_tmp, :string
    add_column :groups, :background_image_processing, :boolean
  end
end
