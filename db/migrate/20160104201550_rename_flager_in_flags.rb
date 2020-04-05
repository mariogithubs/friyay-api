class RenameFlagerInFlags < ActiveRecord::Migration
  def change
    rename_column :flags, :flager_id, :flagger_id
    rename_column :flags, :flager_type, :flagger_type
  end
end
