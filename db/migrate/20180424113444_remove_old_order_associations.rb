class RemoveOldOrderAssociations < ActiveRecord::Migration
  def change
  	remove_reference :users, :label_order, index: true
  	remove_reference :users, :people_order, index: true
  end
end
