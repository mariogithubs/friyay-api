class CreateLabelOrders < ActiveRecord::Migration
  def change
    create_table :label_orders do |t|
      t.string  :name
      t.integer :order, array: true, default: []

      t.timestamps null: false
    end
  end
end
