class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :title
      t.boolean :is_public
      t.timestamps null: false
    end
  end
end
