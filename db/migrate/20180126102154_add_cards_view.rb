class AddCardsView < ActiveRecord::Migration
  def change
  	View.create(name: 'card', kind: 'system')
  end
end
