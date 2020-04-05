class AddExpectedCompletionToTips < ActiveRecord::Migration
  def change
  	add_column :tips, :expected_completion_date, :datetime
  end
end
