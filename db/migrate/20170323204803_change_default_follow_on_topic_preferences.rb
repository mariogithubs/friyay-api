class ChangeDefaultFollowOnTopicPreferences < ActiveRecord::Migration
  def up
    change_column :topic_preferences, :follow_scope, :integer, default: 2

    TopicPreference.where(follow_scope: 0).update_all(follow_scope: 2)
  end
end
