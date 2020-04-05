class RemoveColumnNotificationFrequency < ActiveRecord::Migration
  def change
    remove_column :user_profiles, :notification_frequency, :text
  end
end
