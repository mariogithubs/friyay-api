class CreateSlackTeams < ActiveRecord::Migration
  def change
    create_table :slack_teams do |t|
      t.string :team_id, null: false
      t.integer :domain_id, null: false
      t.string :team_name
      t.string :scope
      t.string :access_token
      t.text :incoming_webhook
      t.text :bot

      t.timestamps null: false
    end
  end
end
