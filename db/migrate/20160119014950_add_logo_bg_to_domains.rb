class AddLogoBgToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :logo, :string
    add_column :domains, :logo_tmp, :string
    add_column :domains, :logo_processing, :boolean

    add_column :domains, :background_image, :string
    add_column :domains, :background_image_tmp, :string
    add_column :domains, :background_image_processing, :boolean
  end
end
