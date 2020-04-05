class AddNotificationDatetimeFieldsToUserProfiles < ActiveRecord::Migration
  def change
    add_column :user_profiles, :daily_sent_at, :datetime
    add_column :user_profiles, :weekly_sent_at, :datetime
  end
end
