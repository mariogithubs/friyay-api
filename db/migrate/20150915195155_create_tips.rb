class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.references :user, index: true, null: false
      t.string :title
      t.text :content
      t.string :slug
      t.integer :color_index
      t.string :access_key
      t.boolean :is_public, null: false, default: false
      t.boolean :is_private, null: false, default: false
      t.hstore :properties
      t.hstore :statistics

      t.timestamps null: false
    end

    add_index :tips, :slug
    add_index :tips, :access_key
    add_index :tips, :title
  end
end
