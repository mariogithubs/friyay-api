class AddTenantNameToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :tenant_name, :string, null: false
    add_index :domains, :tenant_name, unique: true
  end
end
