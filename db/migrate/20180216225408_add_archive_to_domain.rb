class AddArchiveToDomain < ActiveRecord::Migration
  def change
  	add_column :domains, :is_disabled, :boolean, default: false
  	add_column :domains, :is_deleted, :boolean, default: false
  end
end
