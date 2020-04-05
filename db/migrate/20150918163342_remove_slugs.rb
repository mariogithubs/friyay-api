class RemoveSlugs < ActiveRecord::Migration
  def change
    remove_column :tips, :slug
    remove_column :topics, :slug
  end
end
