class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.references :user, index: true, null: false
      t.string :email
      t.string :invitation_token
      t.string :invitation_type
      t.string :invitable_type
      t.integer :invitable_id

      t.timestamps null: false
    end
  end
end
