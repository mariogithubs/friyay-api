class ChangeContentToBodyOnTip < ActiveRecord::Migration
  def change
    rename_column :tips, :content, :body
  end
end
