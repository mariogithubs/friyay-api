class CreateShareSettings < ActiveRecord::Migration
  def change
    create_table :share_settings do |t|
      t.references :user, index: true
      t.string :shareable_object_type
      t.integer :shareable_object_id
      t.string :sharing_object_type
      t.integer :sharing_object_id

      t.timestamps null: false
    end
  end
end
