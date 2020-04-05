class AddLabelableFieldsToLabels < ActiveRecord::Migration
  def change
    add_column :labels, :labelable_id, :integer
    add_column :labels, :labelable_type, :string

    add_index :labels, [:labelable_type, :labelable_id]
  end
end
