class ChangesToQuestions < ActiveRecord::Migration
  def change
    rename_column :questions, :is_public, :share_public
    add_column :questions, :share_following, :boolean, default: false
  end
end
