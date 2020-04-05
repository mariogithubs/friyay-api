class AddStripeCustomerAndCardIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_card_id, :string
  end
end
