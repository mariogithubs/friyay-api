class AddDefaultViewIdToTopic < ActiveRecord::Migration
  def change
    add_column :topics, :default_view_id, :integer
  end
end
