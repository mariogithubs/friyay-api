class UpdateColumnsForPermissions < ActiveRecord::Migration
  def change
    remove_column :activity_permissions, :user_id, :integer
    change_column :activity_permissions, :subject_role, :text, default: ''
  end
end
