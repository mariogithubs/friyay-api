class CreateTipsDependency < ActiveRecord::Migration
  def change
    create_table :tips_dependencies do |t|
    	t.integer :depended_on_by
    	t.integer :depends_on
    end
  end
end
