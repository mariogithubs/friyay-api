class AddTopicToTopicOrder < ActiveRecord::Migration
  def change
  	add_reference :topic_orders, :topic, index: true unless column_exists? :topic_orders, :topic_id
  end
end
