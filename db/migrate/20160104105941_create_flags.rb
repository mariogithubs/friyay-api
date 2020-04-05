class CreateFlags < ActiveRecord::Migration
  def up
    create_table :flags do |t|
      t.integer :flagable_id
      t.string :flagable_type
      t.integer :reason
      t.integer :flager_id
      t.string :flager_type

      t.timestamps null: false
    end

    add_index :flags, :flagable_id
    add_index :flags, :flagable_type
    add_index :flags, :flager_id
    add_index :flags, :flager_type
  end

  def down
    drop_table :flags
  end
end

