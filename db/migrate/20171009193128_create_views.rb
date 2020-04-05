class CreateViews < ActiveRecord::Migration
  STARTING_VIEWS = ['grid', 'small grid', 'list', 'sheet', 'task', 'wiki', 'kanban']

  def up
    create_table :views do |t|
      t.integer :user_id, index: true, null: false, default: 0
      t.string :kind
      t.string :name
      t.jsonb :settings

      t.timestamps null: false
    end

    STARTING_VIEWS.each { |view| View.create(name: view, kind: 'system') }
  end

  def down
    drop_table :views
  end
end
