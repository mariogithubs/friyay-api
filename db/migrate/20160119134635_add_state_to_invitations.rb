class AddStateToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :state, :string, default: 'pending'
  end
end
