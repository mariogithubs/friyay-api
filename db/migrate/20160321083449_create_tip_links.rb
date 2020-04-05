class CreateTipLinks < ActiveRecord::Migration
  def change
    create_table :tip_links do |t|
      t.string :url
      t.integer :tip_id
      t.integer :user_id
      t.string :title
      t.text :description
      t.string :avatar
      t.string :avatar_tmp
      t.boolean :avatar_processing
      t.boolean :processed, default: false

      t.timestamps null: false
    end
  end
end
