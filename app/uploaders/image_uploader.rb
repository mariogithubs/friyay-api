# encoding: utf-8

class ImageUploader < ApplicationUploaderBase
  include ::CarrierWave::Backgrounder::Delay

  def store_dir
    return excluded_models_dir if Apartment.excluded_models.include?(model.class.to_s)

    "storage/#{Apartment::Tenant.current}/images/#{mounted_as}/#{model.id}"
    # "uploads/images/#{mounted_as}/#{model.id}"
  end
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  process :set_content_type

  def update_attachments_json(_file)
    resource = model.try(:attachable)
    return if resource.blank?
    return unless resource.is_a?(Tip)

    resource.process_image_as_attachment_json(model)
  end

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

  version :small, from_version: :medium do
    process resize_to_fit: [500, 500]

    after :store, :update_attachments_json
  end

  version :medium_square do
    process resize_to_fill: [300, 300]
  end

  version :square, from_version: :medium_square do
    process resize_to_fill: [200, 200]
  end

  version :thumb, from_version: :square do
    process resize_to_fill: [40, 40]
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
