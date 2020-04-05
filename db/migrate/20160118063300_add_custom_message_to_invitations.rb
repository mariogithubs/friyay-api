class AddCustomMessageToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :custom_message, :text
  end
end
