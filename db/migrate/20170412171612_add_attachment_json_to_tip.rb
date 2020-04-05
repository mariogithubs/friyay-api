class AddAttachmentJsonToTip < ActiveRecord::Migration
  def change
    add_column :tips, :attachments_json, :jsonb, null: false, default: '{}'
    add_index :tips, :attachments_json, using: :gin
  end
end
