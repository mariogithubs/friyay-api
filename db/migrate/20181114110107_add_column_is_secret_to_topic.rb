class AddColumnIsSecretToTopic < ActiveRecord::Migration
  def change
  	 add_column :topics, :is_secret, :boolean, default: false
  end
end
