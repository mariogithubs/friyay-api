class CreateTopicUsers < ActiveRecord::Migration
  def change
    create_table :topic_users do |t|
      t.integer :follower_id, null: false
      t.integer :user_id, null: false
      t.integer :topic_id, null: false
      t.integer :status, null: false, default: 0, index: { with: [:follower_id, :topic_id] }

      t.timestamps null: false
    end
  end
end
