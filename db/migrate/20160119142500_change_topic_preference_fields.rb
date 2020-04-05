class ChangeTopicPreferenceFields < ActiveRecord::Migration
  def up
    remove_column :topic_preferences, :is_public
    remove_column :topic_preferences, :is_private
    remove_column :topic_preferences, :is_on_profile
    remove_column :topic_preferences, :shared_all_friends
    add_column :topic_preferences, :share_public, :boolean, default: true
    add_column :topic_preferences, :share_following, :boolean, default: false
  end

  def down
    add_column :topic_preferences, :is_public, :boolean, default: true
    add_column :topic_preferences, :is_private, :boolean, default: false
    add_column :topic_preferences, :is_on_profile, :boolean, default: true
    add_column :topic_preferences, :shared_all_friends, :boolean, default: false
    remove_column :topic_preferences, :share_public
    remove_column :topic_preferences, :share_following
  end
end
