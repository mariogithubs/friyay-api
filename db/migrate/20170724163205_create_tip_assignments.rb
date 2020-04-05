class CreateTipAssignments < ActiveRecord::Migration
  def change
    create_table :tip_assignments do |t|
      t.integer :user_id
      t.integer :tip_id

      t.timestamps null: false
    end
  end
end
