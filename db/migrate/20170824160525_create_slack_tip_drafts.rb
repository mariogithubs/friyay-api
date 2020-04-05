class CreateSlackTipDrafts < ActiveRecord::Migration
  def change
    unless table_exists? :slack_tip_drafts
      create_table :slack_tip_drafts do |t|
        t.string :title
        t.text :body
        t.boolean :is_draft
        t.references :slack_member, index: true, foreign_key: true

        t.timestamps null: false
      end
    end
  end
end
