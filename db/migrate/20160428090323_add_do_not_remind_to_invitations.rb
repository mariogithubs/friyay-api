class AddDoNotRemindToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :do_not_remind, :boolean, default: false
  end
end
