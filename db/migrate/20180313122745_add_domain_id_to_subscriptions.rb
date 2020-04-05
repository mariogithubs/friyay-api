class AddDomainIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :domain_id, :integer
  end
end
