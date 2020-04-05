class AddOriginalUrlToAttachments < ActiveRecord::Migration
  def change
    unless column_exists? :attachments, :original_url
      add_column :attachments, :original_url, :string
    end
  end
end
