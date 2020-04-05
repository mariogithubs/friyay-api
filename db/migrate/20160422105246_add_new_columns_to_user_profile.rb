class AddNewColumnsToUserProfile < ActiveRecord::Migration
  def change
    add_column :user_profiles, :follow_all_members, :boolean, default: true
    add_column :user_profiles, :follow_all_hives, :boolean, default: true
  end
end
