class UpdateColumnsDatesToTips < ActiveRecord::Migration
  def change
    change_column :tips, :start_date, :datetime
    change_column :tips, :due_date, :datetime
    change_column :tips, :completion_date, :datetime   
  end
end
