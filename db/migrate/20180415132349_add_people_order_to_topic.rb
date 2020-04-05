class AddPeopleOrderToTopic < ActiveRecord::Migration
  def change
  	add_reference :topics, :people_order, index: true, foreign_key: true
  end
end
