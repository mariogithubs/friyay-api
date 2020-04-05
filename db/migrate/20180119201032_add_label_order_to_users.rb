class AddLabelOrderToUsers < ActiveRecord::Migration
  def change
  	add_reference :users, :label_order, index: true, foreign_key: true
  end
end
