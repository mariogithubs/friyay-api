class AddDontShowCardsOnParentTopicToTopics < ActiveRecord::Migration
  def change
  	add_column :topics, :show_tips_on_parent_topic, :boolean, default: true
  end
end
