class CreateUserTopicLabelOrders < ActiveRecord::Migration
  def change
    create_table :user_topic_label_orders do |t|
      t.belongs_to :user
      t.belongs_to :topic
      t.belongs_to :label_order
    end
  end
end
