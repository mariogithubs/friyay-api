class ChangeTopicProfileToTopicPreferences < ActiveRecord::Migration
  def change
    rename_table :topic_profiles, :topic_preferences if table_exists?(:topic_profiles)
  end
end
