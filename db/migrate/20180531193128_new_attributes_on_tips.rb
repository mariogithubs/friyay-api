class NewAttributesOnTips < ActiveRecord::Migration
  def change
  	add_column :tips, :actual_work, :integer
  	add_column :tips, :confidence_range, :integer
  	add_column :tips, :resource_expended, :decimal
  end
end
