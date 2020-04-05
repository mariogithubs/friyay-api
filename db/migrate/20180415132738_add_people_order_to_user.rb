class AddPeopleOrderToUser < ActiveRecord::Migration
  def change
  	add_reference :users, :people_order, index: true, foreign_key: true
  end
end
