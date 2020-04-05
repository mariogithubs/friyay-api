class RemoveStripeIdsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :stripe_customer_id
    remove_column :users, :stripe_card_id 
  end
end
