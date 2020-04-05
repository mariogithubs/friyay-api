class CreateJoinTableUserTopicOrder < ActiveRecord::Migration
  def change
    create_join_table :users, :topic_orders do |t|
      t.index [:user_id, :topic_order_id]
      t.index [:topic_order_id, :user_id]
    end
  end
end
