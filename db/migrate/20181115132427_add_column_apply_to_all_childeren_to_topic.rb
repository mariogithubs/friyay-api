class AddColumnApplyToAllChilderenToTopic < ActiveRecord::Migration
  def change
  	add_column :topics, :apply_to_all_childrens, :boolean, default: false
  end
end
