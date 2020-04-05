class ExtractTopicPreferenceSettings < ActiveRecord::Migration
  def change
    remove_column :topic_preferences, :settings

    change_table :topic_preferences do |t|
      t.boolean :is_public, default: false, index: true
      t.boolean :is_on_profile, default: true, index: true
      t.boolean :is_private, default: false, index: true
      t.boolean :shared_all_friends, default: false, index: true
    end
  end
end
