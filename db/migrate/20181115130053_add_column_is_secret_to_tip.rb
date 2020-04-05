class AddColumnIsSecretToTip < ActiveRecord::Migration
  def change
  	add_column :tips, :is_secret, :boolean, default: false
  end
end
