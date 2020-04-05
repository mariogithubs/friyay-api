class AddValueAndEffortToTips < ActiveRecord::Migration
  def change
  	add_column :tips, :value, :integer unless column_exists? :tips, :value
  	add_column :tips, :effort, :integer unless column_exists? :tips, :effort
  end
end
