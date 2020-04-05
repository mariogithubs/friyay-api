class CreateDomainMemberships < ActiveRecord::Migration
  def change
    create_table :domain_memberships do |t|
      t.references :user, index: true, null: false
      t.references :domain, index: true, null: false
      t.string :role, default: 'member', null: false

      t.timestamps null: false
    end
  end
end
