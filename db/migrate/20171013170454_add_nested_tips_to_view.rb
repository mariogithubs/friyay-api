class AddNestedTipsToView < ActiveRecord::Migration
  def change
    add_column :views, :show_nested_tips, :boolean, null: false, default: true
  end
end
