class AddExpirationDateToTips < ActiveRecord::Migration
  def change
    add_column :tips, :expiration_date, :datetime
    add_column :tips, :is_disabled, :boolean, default: false
  end
end
