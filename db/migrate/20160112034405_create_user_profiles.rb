class CreateUserProfiles < ActiveRecord::Migration
  def change
    create_table :user_profiles do |t|
      t.integer :user_id
      t.string :avatar
      t.string :avatar_tmp
      t.boolean :avatar_processing
      t.string :background_image
      t.boolean :background_image_processing
      t.string :background_image_tmp
      t.string :notification_frequency

      t.timestamps null: false
    end
  end
end
