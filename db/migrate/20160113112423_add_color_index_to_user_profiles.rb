class AddColorIndexToUserProfiles < ActiveRecord::Migration
  def change
    add_column :user_profiles, :color_index, :integer, default: rand(1..7)
  end
end
