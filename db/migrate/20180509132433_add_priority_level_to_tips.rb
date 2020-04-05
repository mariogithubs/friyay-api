class AddPriorityLevelToTips < ActiveRecord::Migration
  def change
  	add_column :tips, :priority_level, :string unless column_exists? :tips, :priority_level
  end
end
