class RenameColumnInAttachments < ActiveRecord::Migration
  def change
    rename_column :attachments, :zencoder_output_id, :name_tmp
    rename_column :attachments, :processed, :name_processing
  end
end
