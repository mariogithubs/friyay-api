class AddDomainIdToContactInformation < ActiveRecord::Migration
  def change
    add_column :contact_informations, :domain_id, :integer
  end
end
