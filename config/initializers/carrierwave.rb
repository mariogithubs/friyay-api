# if Rails.env.test? || Rails.env.cucumber?
#   CarrierWave.configure do |config|
#     config.storage = :file
#     config.enable_processing = false
#   end

#   # make sure our uploader is auto-loaded
#   ImageUploader

#   # use different dirs when testing
#   CarrierWave::Uploader::Base.descendants.each do |klass|
#     next if klass.anonymous?
#     klass.class_eval do
#       def cache_dir
#         "#{Rails.root}/spec/support/uploads/tmp"
#       end

#       def store_dir
#         "#{Rails.root}/spec/support/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
#       end
#     end
#   end
# end

CarrierWave.configure do |config|
  config.storage = :fog
  # FOG AWS
  if ENV['FOG_PROVIDER'] == 'AWS'
    config.fog_credentials = {
      provider: ENV['FOG_PROVIDER'],
      aws_access_key_id: ENV['FOG_AWS_KEY'],
      aws_secret_access_key: ENV['FOG_AWS_SECRET'],
      region: ENV['FOG_AWS_REGION']
    }
    config.fog_directory = ENV['FOG_AWS_BUCKET']
  end

  # FOG LOCAL
  if ENV['FOG_PROVIDER'] == 'Local'
    config.fog_credentials = {
      provider: ENV['FOG_PROVIDER'],
      local_root: ENV['FOG_LOCAL_ROOT'],
      endpoint: ENV['FOG_ENDPOINT']
    }
    config.fog_directory = ENV['FOG_DIRECTORY']
  end
end
