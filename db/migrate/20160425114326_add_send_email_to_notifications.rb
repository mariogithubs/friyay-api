class AddSendEmailToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :send_email, :boolean, default: true
  end
end
