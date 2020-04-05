class RemovePermissions < ActiveRecord::Migration
  def change
    ActivityPermission.destroy_all
  end
end
