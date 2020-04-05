class AddIssuerToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :issuer, :string
  end
end
