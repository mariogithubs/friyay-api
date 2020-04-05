class AddDailySentAtToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :daily_sent_at, :datetime
  end
end
