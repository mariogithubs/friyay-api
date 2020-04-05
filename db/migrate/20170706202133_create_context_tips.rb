class CreateContextTips < ActiveRecord::Migration
  def change
    unless table_exists?(:context_tips)
      create_table :context_tips do |t|
        t.string :context_id
        t.integer :tip_id, index: true, null: false
        t.integer :position, index: true

        t.timestamps null: false
      end
    end
  end
end
