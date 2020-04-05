class ChangeAttachmentsNameToFile < ActiveRecord::Migration
  def change
    rename_column :attachments, :name, :file
    rename_column :attachments, :name_processing, :file_processing
    rename_column :attachments, :name_tmp, :file_tmp
  end
end
