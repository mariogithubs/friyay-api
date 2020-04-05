class AddLinkShareToTopicPreference < ActiveRecord::Migration
  def change
  	add_column :topic_preferences, :link_option, :text
  	add_column :topic_preferences, :link_password, :string
  end
end

