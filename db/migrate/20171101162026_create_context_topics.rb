class CreateContextTopics < ActiveRecord::Migration
  def change
    create_table :context_topics do |t|
      t.string :context_id
      t.integer :topic_id, null: false, index: true
      t.integer :position, index: true

      t.timestamps null: false
    end
  end
end
