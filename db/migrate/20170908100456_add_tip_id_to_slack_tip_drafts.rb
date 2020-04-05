class AddTipIdToSlackTipDrafts < ActiveRecord::Migration
  def change
    unless column_exists? :slack_tip_drafts, :tip_id
      add_column :slack_tip_drafts, :tip_id, :integer
    end
  end
end
