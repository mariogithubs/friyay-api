class CreateSlackChannels < ActiveRecord::Migration
  def change
    unless table_exists? :slack_channels
      create_table :slack_channels do |t|
        t.string :name
        t.string :slack_channel_id
        t.integer :slack_team_id

        t.timestamps null: false
      end
    end
  end
end
