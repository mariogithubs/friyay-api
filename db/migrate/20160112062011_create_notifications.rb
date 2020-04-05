class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :notifier_id
      t.string :type
      t.string :action
      t.string :notifiable_type
      t.integer :notifiable_id

      t.timestamps null: false
    end
  end
end
