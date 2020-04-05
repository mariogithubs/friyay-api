class AddIsProcessedToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :is_processed, :boolean, default: false
    add_column :notifications, :frequency, :string
  end
end
