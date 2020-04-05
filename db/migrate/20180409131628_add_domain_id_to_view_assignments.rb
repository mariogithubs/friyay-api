class AddDomainIdToViewAssignments < ActiveRecord::Migration
  def change
    add_column :view_assignments, :domain_id, :integer
  end
end
