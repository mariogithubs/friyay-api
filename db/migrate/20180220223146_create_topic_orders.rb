class CreateTopicOrders < ActiveRecord::Migration
  def change
    create_table :topic_orders do |t|
      t.string :subtopic_order, array: true, default: []
      t.string :tip_order, array: true, default: []

      t.references :topic, index: true, null: false
      t.references :order, index: true, null: false

      t.timestamps null: false
    end

    create_table :topic_orders_topics, id: false do |t|
      t.belongs_to :topic_order, index: true
      t.belongs_to :topic, index: true
    end

    create_table :topic_orders_tips, id: false do |t|
      t.belongs_to :topic_order, index: true
      t.belongs_to :tip, index: true
    end
  end
end
