class AddGuestSupportingFieldsToTables < ActiveRecord::Migration
  def change
    add_column :invitations, :options, :jsonb, null: false, default: '{}'
    add_index :invitations, :options, using: :gin

    add_column :domain_memberships, :invitation_id, :integer, index: true
  end
end
