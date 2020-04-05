class ChangesToTips < ActiveRecord::Migration
  def change
    rename_column :tips, :is_private, :share_following
    rename_column :tips, :is_public, :share_public
  end
end
