class AddUserToAttachments < ActiveRecord::Migration
  def change
    add_reference :attachments, :user, index: true, foreign_key: true
  end
end
