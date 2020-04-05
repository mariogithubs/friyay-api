class CreateGlobalTemplates < ActiveRecord::Migration
  def change
    create_table :global_templates do |t|
      t.integer :user_id
      t.string :template_type
      t.string :title

      t.timestamps null: false
    end
  end
end
