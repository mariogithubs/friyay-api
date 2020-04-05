class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.integer :user_id
      t.string :name
      t.string :color
      t.string :kind

      t.timestamps null: false
    end
  end
end
