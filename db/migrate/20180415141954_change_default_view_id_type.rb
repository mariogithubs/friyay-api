class ChangeDefaultViewIdType < ActiveRecord::Migration
  def change
    if column_exists? :topics, :default_view_id
  	 change_column :topics, :default_view_id, :string
    else
      add_column :topics, :default_view_id, :string
    end
  end
end
