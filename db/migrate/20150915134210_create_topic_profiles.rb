class CreateTopicProfiles < ActiveRecord::Migration
  def change
    create_table :topic_profiles do |t|
      t.references :topic, index: true, foreign_key: true, null: false
      t.references :user, index: true, null: false
      t.integer :background_color_index, null: false, default: 1
      t.string :background_image, null: false, default: ''
      t.hstore :settings, null: false, default: ''

      t.timestamps null: false
    end
  end
end
