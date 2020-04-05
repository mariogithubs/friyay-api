class AddUpgradeToRoleToDomainMembership < ActiveRecord::Migration
  def change
    add_column :domain_memberships, :upgrade_to_role, :string
  end
end
