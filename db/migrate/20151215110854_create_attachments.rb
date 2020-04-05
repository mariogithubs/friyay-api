class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :name
      t.string :type
      t.string :attachable_type
      t.integer :attachable_id
      t.boolean :processed
      t.string :zencoder_output_id

      t.timestamps null: false
    end
  end
end
