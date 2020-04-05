class ChangeContextsCompletely < ActiveRecord::Migration
  def up
    drop_table :contexts if table_exists?(:contexts)

    create_table :contexts, id: false do |t|
      t.string :context_uniq_id, null: false

      t.timestamps null: false
    end

    add_index :contexts, :context_uniq_id, unique: true
  end
end
