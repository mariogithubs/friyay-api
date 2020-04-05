class ChangeTopicIdToStringInSlackTopicConnection < ActiveRecord::Migration
  def change
  	change_column :slack_topic_connections, :topic_id, :string
  end
end
