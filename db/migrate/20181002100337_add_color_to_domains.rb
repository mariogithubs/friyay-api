class AddColorToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :color, :string
  end
end
