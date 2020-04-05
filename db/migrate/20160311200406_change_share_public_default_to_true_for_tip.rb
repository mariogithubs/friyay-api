class ChangeSharePublicDefaultToTrueForTip < ActiveRecord::Migration
  def self.up
    change_column :tips, :share_public, :boolean, default: true
  end

  def self.down
    change_column :tips, :share_public, :boolean, default: false
  end
end
