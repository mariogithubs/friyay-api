class CreateIndexes < ActiveRecord::Migration
  def change
    add_index :roles, :id, unique: true, using: :btree
    add_index :roles, :name
    add_index :roles, :resource_id
    add_index :roles, :resource_type
  end
end
