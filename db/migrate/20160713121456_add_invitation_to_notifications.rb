class AddInvitationToNotifications < ActiveRecord::Migration
  def change
    add_reference :notifications, :invitation, index: true, foreign_key: true
  end
end
