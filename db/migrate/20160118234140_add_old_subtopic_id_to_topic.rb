class AddOldSubtopicIdToTopic < ActiveRecord::Migration
  def change
    add_column :topics, :old_subtopic_id, :integer
  end
end
