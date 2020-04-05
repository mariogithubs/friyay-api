class AddColumnsToSlackMembers < ActiveRecord::Migration
  def change
    unless column_exists? :slack_members, :gravatar_url
      add_column :slack_members, :gravatar_url, :string
    end
  end
end
