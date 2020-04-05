class AddFieldUserIdsToSlackTeam < ActiveRecord::Migration
  def change
  	add_column :slack_teams, :user_ids, :string, array: true, default: []
  end
end
