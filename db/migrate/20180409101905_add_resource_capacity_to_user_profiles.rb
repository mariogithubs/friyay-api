class AddResourceCapacityToUserProfiles < ActiveRecord::Migration
  def change
  	add_column :user_profiles, :resource_capacity, :integer
  end
end
