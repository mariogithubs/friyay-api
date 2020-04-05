# encoding: utf-8

class BackgroundImageUploader < ApplicationUploaderBase
  include ::CarrierWave::Backgrounder::Delay

  def store_dir
    return excluded_models_dir if Apartment.excluded_models.include?(model.class.to_s)

    "storage/#{Apartment::Tenant.current}/background_images/#{mounted_as}/#{model.id}"

    # "uploads/images/#{mounted_as}/#{model.id}"
    # "#{current_domain}/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  process :set_content_type

  # Choose what kind of storage to use for this uploader:
  # storage :file
  # storage :fog

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :large do
    process resize_to_fit: [1920, 1280]
  end

  version :medium, from_version: :large do
    process resize_to_fit: [1280, 1024]
  end

  # version :small, from_version: :medium do
  #   process resize_to_fit: [1024, 768]
  # end

  # version :large_square do
  #   process resize_to_fill: [500, 500]
  # end

  version :square, from_version: :medium do
    process resize_to_fill: [100, 100]
  end

  version :thumb, from_version: :square do
    process resize_to_fit: [50, 50]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
