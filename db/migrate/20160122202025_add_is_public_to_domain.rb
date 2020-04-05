class AddIsPublicToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :is_public, :boolean, default: false
  end
end
