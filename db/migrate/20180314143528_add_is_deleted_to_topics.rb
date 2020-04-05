class AddIsDeletedToTopics < ActiveRecord::Migration
  def change
  	add_column :topics, :is_deleted, :boolean, default: false
  	add_column :topics, :is_disabled, :boolean, default: false
  	add_column :tips, :is_deleted, :boolean, default: false
  end
end
