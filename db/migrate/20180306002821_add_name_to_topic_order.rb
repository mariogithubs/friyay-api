class AddNameToTopicOrder < ActiveRecord::Migration
  def change
  	add_column :topic_orders, :name, :string
  end
end
