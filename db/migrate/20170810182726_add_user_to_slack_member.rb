class AddUserToSlackMember < ActiveRecord::Migration
  def change
    unless column_exists? :slack_members, :user_id
      add_column :slack_members, :user_id, :integer
    end
  end
end
