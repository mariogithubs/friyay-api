class CreateSpamRecords < ActiveRecord::Migration
  def change
    create_table :spam_records do |t|
      t.string :to
      t.string :from
      t.string :subject
      t.text :html
      t.string :spam_score
      t.text :spam_report
      t.string :envelope

      t.timestamps null: false
    end
  end
end
