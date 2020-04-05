class AddOldResourceIdToAttachment < ActiveRecord::Migration
  def change
    add_column :attachments, :old_resource_id, :integer
  end
end
