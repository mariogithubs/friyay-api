class RemoveAvatarFromTopics < ActiveRecord::Migration
  def change
    remove_column :topic_preferences, :avatar, :string
    remove_column :topic_preferences, :avatar_tmp, :string
    remove_column :topic_preferences, :avatar_processing, :boolean
  end
end
