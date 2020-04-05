class UpdateDefaultDomainViewType < ActiveRecord::Migration
  def change
    if column_exists? :domains, :default_view_id
      change_column :domains, :default_view_id, :string
    else
      add_column :domains, :default_view_id, :string
    end
  end
end
