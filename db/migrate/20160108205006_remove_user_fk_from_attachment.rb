class RemoveUserFkFromAttachment < ActiveRecord::Migration
  def change
    remove_foreign_key :attachments, :user
  end
end
