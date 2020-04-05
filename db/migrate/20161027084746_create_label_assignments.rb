class CreateLabelAssignments < ActiveRecord::Migration
  def change
    create_table :label_assignments do |t|
      t.references :label, index: true, foreign_key: true
      t.integer :item_id
      t.string :item_type

      t.timestamps null: false
    end

    add_index :label_assignments, [:item_type, :item_id]
  end
end
