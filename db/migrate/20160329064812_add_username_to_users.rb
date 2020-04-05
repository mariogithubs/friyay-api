class AddUsernameToUsers < ActiveRecord::Migration
  def up
    add_column :users, :username, :string

    sql = 'SELECT CONCAT(first_name, last_name) as full_name,MIN(id) id FROM users GROUP BY full_name ORDER BY id'
    update_sql = "UPDATE users SET username = replace(CONCAT(first_name, last_name), ' ', '_') WHERE id IN (SELECT id FROM (#{sql}) A);"
    ActiveRecord::Base.connection.execute update_sql

    sql = "UPDATE users SET username = replace(CONCAT(first_name, last_name, id), ' ', '_') WHERE username IS NULL;"
    ActiveRecord::Base.connection.execute sql

    change_column :users, :username, :string, null: false
    add_index :users, :username, unique: true
  end

  def down
    remove_column :users, :username
  end
end
