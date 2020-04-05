class CreateLabelCategories < ActiveRecord::Migration
  def change
    create_table :label_categories do |t|
    	t.string :name
    end

    create_table :labels_label_categories, id: false do |t|
      t.belongs_to :label, index: true
      t.belongs_to :label_category, index: true
    end

  end
end
