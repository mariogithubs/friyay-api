class RemoveAuthenticationTokenFromUsers < ActiveRecord::Migration
  def change
    remove_index :users, :authentication_token
    remove_column :users, :authentication_token
  end
end
