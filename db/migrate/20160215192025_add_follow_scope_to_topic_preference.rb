class AddFollowScopeToTopicPreference < ActiveRecord::Migration
  def change
    add_column :topic_preferences, :follow_scope, :integer, default: 2
  end
end
