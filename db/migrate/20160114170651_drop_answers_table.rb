class DropAnswersTable < ActiveRecord::Migration
  def change
    drop_table :answers if table_exists?(:answers)
  end
end
