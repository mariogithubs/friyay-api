class AddIsDefaultToLabelOrders < ActiveRecord::Migration
  def change
    add_column :label_orders, :is_default, :boolean
  end
end
