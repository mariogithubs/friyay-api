class RemoveOrderFromTopicOrder < ActiveRecord::Migration
  def change
  	remove_column :topic_orders, :order_id
  end
end
