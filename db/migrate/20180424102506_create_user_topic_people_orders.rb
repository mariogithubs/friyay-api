class CreateUserTopicPeopleOrders < ActiveRecord::Migration
  def change
    create_table :user_topic_people_orders do |t|
 	  t.belongs_to :user
      t.belongs_to :topic
      t.belongs_to :people_order    	
    end
  end
end
