class AddTopicIdToContext < ActiveRecord::Migration
  def change
    add_column :contexts, :topic_id, :integer
  end
end
