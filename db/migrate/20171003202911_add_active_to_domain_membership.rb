class AddActiveToDomainMembership < ActiveRecord::Migration
  def change
    add_column :domain_memberships, :active, :boolean, null: false, default: true

    DomainMembership.update_all(active: true)
  end
end
