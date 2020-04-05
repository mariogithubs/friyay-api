class AddZencoderFieldsToAttachments < ActiveRecord::Migration
  def change
    add_column :attachments, :zencoder_output_id, :string
    add_column :attachments, :zencoder_processed, :boolean, default: false
  end
end
