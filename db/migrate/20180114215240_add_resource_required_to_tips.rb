class AddResourceRequiredToTips < ActiveRecord::Migration
  def change
  	add_column :tips, :resource_required, :decimal
  end
end
