class RemoveLabelableFromLabels < ActiveRecord::Migration
  def change
    remove_index :labels, column: [:labelable_type, :labelable_id]

    remove_column :labels, :labelable_id
    remove_column :labels, :labelable_type
  end
end
