class AddTimeStampsToLabelCategories < ActiveRecord::Migration
  def change
  	add_timestamps :label_categories, null: false
  end
end
