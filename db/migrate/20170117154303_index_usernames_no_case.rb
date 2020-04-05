class IndexUsernamesNoCase < ActiveRecord::Migration
  def change
    remove_index :users, :username
    add_index :users, :username, case_sensitive: false, unique: true
  end
end
