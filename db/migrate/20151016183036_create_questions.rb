class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :title
      t.references :user, index: true, null: false
      t.text :body
      t.boolean :is_public, null: false, default: true

      t.timestamps null: false
    end
  end
end
