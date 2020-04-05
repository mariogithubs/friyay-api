class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.text :description
      t.integer :user_id, null: false
      t.string :slug, unique: true, null: false

      t.timestamps null: false
    end

    add_index :topics, :user_id
    add_index :topics, :slug
  end
end
