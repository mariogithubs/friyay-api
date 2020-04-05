class AddOrderToUsers < ActiveRecord::Migration
  def change
  	add_reference :users, :order, index: true, foreign_key: true
  end
end
