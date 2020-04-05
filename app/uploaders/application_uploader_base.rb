class ApplicationUploaderBase < CarrierWave::Uploader::Base
  def excluded_models_dir
    "storage/#{model.class.to_s.tableize}/#{mounted_as}/#{model.id}"
  end
end
