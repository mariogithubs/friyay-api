class CreatePeopleOrders < ActiveRecord::Migration
  def change
    create_table :people_orders do |t|
      t.string  :name
      t.string :order, array: true, default: []
      t.timestamps null: false
    end
  end
end
