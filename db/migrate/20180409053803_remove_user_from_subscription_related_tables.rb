class RemoveUserFromSubscriptionRelatedTables < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :user_id
    remove_column :contact_informations, :user_id
  end
end
