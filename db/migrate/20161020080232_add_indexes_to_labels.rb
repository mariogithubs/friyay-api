class AddIndexesToLabels < ActiveRecord::Migration
  def change
    add_index :labels, :color
    add_index :labels, :kind

    add_foreign_key :labels, :users
  end
end
