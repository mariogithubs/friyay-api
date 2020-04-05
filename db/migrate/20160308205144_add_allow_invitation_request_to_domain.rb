class AddAllowInvitationRequestToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :allow_invitation_request, :boolean, null: false, default: false
  end
end
