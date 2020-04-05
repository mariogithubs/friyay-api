class AddCardsHiddenToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :cards_hidden, :boolean
  end
end
