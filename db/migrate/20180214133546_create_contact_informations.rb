class CreateContactInformations < ActiveRecord::Migration
  def change
    create_table :contact_informations do |t|
      t.string :first_name
      t.string :last_name
      t.string :company_name
      t.string :address
      t.string :appartment
      t.string :city
      t.string :country
      t.string :state
      t.string :zip
      t.integer :subscription_id
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
