class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.references :user, index: true, null: false
      t.string :title
      t.text :description
      t.string :join_type
      t.string :group_type
      t.integer :color_index
      t.string :background_image
      t.integer :image_top
      t.integer :image_left
      t.string :address
      t.string :location
      t.string :zip
      t.float :latitude
      t.float :longitude
      t.string :avatar
      t.string :admin_ids
      t.boolean :is_auto_accept

      t.timestamps null: false
    end
  end
end
