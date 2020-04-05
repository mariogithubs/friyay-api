class AddCardAndCustomerIdToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :stripe_customer_id, :string
    add_column :domains, :stripe_card_id, :string
  end
end
