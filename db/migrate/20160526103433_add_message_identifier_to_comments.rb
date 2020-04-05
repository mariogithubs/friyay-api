class AddMessageIdentifierToComments < ActiveRecord::Migration
  def change
    unless column_exists? :comments, :message_identifier
      add_column :comments, :message_identifier, :string
    end
  end
end
