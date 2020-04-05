class CreateActivityPermissions < ActiveRecord::Migration
  def change
    create_table :activity_permissions do |t|
      t.integer :user_id
      t.string :permissible_type
      t.integer :permissible_id
      t.string :action
      t.string :subject_class
      t.text :description
      t.string :subject_role

      t.timestamps null: false
    end
  end
end
