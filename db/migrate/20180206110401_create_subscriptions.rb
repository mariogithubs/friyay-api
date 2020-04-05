class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :stripe_subscription_id
      t.integer :user_id
      t.datetime :start_date
      t.string :tenure
      t.timestamps null: false
    end
  end
end
