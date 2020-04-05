class AddRefrencesToOrders < ActiveRecord::Migration
  def change
  	remove_reference :users, :label_order, index: true, foreign_key: true
  	remove_reference :users, :people_order, index: true, foreign_key: true

  	add_reference :users, :label_order, index: true
  	add_reference :users, :people_order, index: true
  end
end
