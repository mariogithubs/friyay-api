class AddDefaultViewIdToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :default_view_id, :integer    
  end
end
