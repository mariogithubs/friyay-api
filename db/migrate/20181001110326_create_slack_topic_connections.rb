class CreateSlackTopicConnections < ActiveRecord::Migration
  def change
    unless table_exists? :slack_topic_connections
      create_table :slack_topic_connections do |t|
      	t.integer :slack_team_id
      	t.integer :slack_channel_id
      	t.integer :topic_id
      	t.integer :domain_id
      	t.integer :user_id

        t.timestamps null: false
      end
    end
  end
end
