class ChangeColumnsInFlags < ActiveRecord::Migration
  def up
    change_column :flags, :reason, :string
    rename_column :flags, :flagable_id, :flaggable_id
    rename_column :flags, :flagable_type, :flaggable_type
  end

  def down
    rename_column :flags, :flaggable_id, :flagable_id
    rename_column :flags, :flaggable_type, :flagable_type
  end
end
