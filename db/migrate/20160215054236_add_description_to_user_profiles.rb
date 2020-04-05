class AddDescriptionToUserProfiles < ActiveRecord::Migration
  def change
    unless column_exists? :user_profiles, :description
      add_column :user_profiles, :description, :text
    end
  end
end
