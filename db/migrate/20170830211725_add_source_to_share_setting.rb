class AddSourceToShareSetting < ActiveRecord::Migration
  def change
    add_column :share_settings, :source, :string
  end
end
