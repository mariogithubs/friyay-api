class CreateSubscriptionPlans < ActiveRecord::Migration
  def change
    create_table :subscription_plans do |t|
      t.string :name
      t.float  :amount
      t.string   :interval
      t.string :stripe_plan_id
      t.timestamps null: false
    end
  end
end

