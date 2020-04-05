class AddStartDueCompletionDatesToTips < ActiveRecord::Migration
  def change
    add_column :tips, :start_date, :date
    add_column :tips, :due_date, :date
    add_column :tips, :completion_date, :date
    add_column :tips, :completed_percentage, :integer, default: 0
    add_column :tips, :work_estimation, :integer
  end
end
