class AddJoinTypeToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :join_type, :integer, default: 0, null: false
  end
end
