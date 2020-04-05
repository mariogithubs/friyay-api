class AddMessagesToAttachments < ActiveRecord::Migration
  def change
    unless column_exists? :attachments, :messages
      add_column :attachments, :messages, :text
    end
  end
end
