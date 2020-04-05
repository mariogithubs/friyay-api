class AddBodyMdToTip < ActiveRecord::Migration
  def change
    def change
      unless column_exists? :tips, :body_md
        add_column :tips, :body_md, :text
      end
    end
  end
end
