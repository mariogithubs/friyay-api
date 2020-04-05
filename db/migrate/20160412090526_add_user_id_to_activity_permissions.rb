class AddUserIdToActivityPermissions < ActiveRecord::Migration
  def change
    add_column :activity_permissions, :user_id, :integer
  end
end
