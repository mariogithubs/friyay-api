class AddDefaultViewToTopicOrders < ActiveRecord::Migration
  def change
  	add_column :topic_orders, :is_default, :boolean, default: false
  end
end
