class CreateSlackMembers < ActiveRecord::Migration
  def change
    unless table_exists? :slack_members
      create_table :slack_members do |t|
        t.string :name
        t.string :slack_member_id
        t.integer :slack_team_id

        t.timestamps null: false
      end
    end
  end
end
