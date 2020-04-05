class AddLabelOrderToTopic < ActiveRecord::Migration
  def change
  	add_reference :topics, :label_order, index: true, foreign_key: true
  end
end
