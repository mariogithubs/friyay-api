class CreateViewAssignments < ActiveRecord::Migration
  def change
    create_table :view_assignments do |t|
      t.integer :user_id
      t.integer :view_id
      t.timestamps null: false
    end
  end
end
