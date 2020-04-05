class AddEmailDomainsToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :email_domains, :string
  end
end
