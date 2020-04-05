class AddGroupsToTipAssignment < ActiveRecord::Migration
  def change
  	rename_column :tip_assignments, :user_id, :assignment_id
  	add_column :tip_assignments, :assignment_type, :string
  end
end
