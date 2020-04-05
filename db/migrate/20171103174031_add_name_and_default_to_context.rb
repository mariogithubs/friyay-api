class AddNameAndDefaultToContext < ActiveRecord::Migration
  def change
    add_column :contexts, :name, :string
    add_column :contexts, :default, :boolean, default: false
  end
end
