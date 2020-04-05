class CreateContexts < ActiveRecord::Migration
  def change
    create_table :contexts do |t|
      t.integer :topic_id, index: true, null: false
      t.integer :user_id, index: true, null: false

      t.timestamps null: false
    end
  end
end
