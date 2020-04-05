class AddImageColumnsToTopicPreferences < ActiveRecord::Migration
  def change
    add_column :topic_preferences, :avatar, :string
    add_column :topic_preferences, :avatar_tmp, :string
    add_column :topic_preferences, :avatar_processing, :boolean
    add_column :topic_preferences, :background_image_tmp, :string
    add_column :topic_preferences, :background_image_processing, :boolean
  end
end
