class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists do |t|
      t.references :user, index: true, null: false
      t.string :name

      t.timestamps null: false
    end
  end
end
