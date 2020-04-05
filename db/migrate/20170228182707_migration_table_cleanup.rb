class MigrationTableCleanup < ActiveRecord::Migration
  def change
    return true if table_exists?(:mentions)

    create_table :mentions do |t|
      t.integer :user_id
      t.integer :mentionable_id
      t.string :mentionable_type

      t.timestamps null: false
    end
  end
end
