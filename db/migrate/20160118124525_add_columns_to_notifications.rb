class AddColumnsToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :email_sent_at, :datetime
    add_column :notifications, :read_at, :datetime
  end
end
