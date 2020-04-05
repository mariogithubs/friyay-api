class VideoUploader < ApplicationUploaderBase
  include ::CarrierWave::Backgrounder::Delay

  include Rails.application.routes.url_helpers

  storage :fog

  after :store, :zencode

  default_content_type  'video/mpeg'
  allowed_content_types %w(video/mpeg video/mp4 video/ogg)

  def will_include_content_type
    true
  end

  def store_dir
    return excluded_models_dir if Apartment.excluded_models.include?(model.class.to_s)

    "storage/#{Apartment::Tenant.current}/videos/#{mounted_as}/#{model.id}"
    # "uploads/videos/#{mounted_as}/#{model.id}"
  end

  def thumbnail_url
    @thubnail_url ||= url_for_format('thumbnail', 'png')
  end

  def mp4_url
    @mp4_url ||= url_for_format('mp4')
  end

  def webm_url
    @webm_url ||= url_for_format('webm')
  end

  def ogv_url
    @ogv_url ||= url_for_format('ogv')
  end

  private

  def zencode(_args = {}) # rubocop:disable Metrics/MethodLength
    bucket = VideoUploader.fog_directory
    input = "s3://#{bucket}/#{path}"
    base_url = "s3://#{bucket}/#{store_dir}"

    params = {
      input: input,
      notifications: ['https://api2.friyayapp.io/zencoder-callback'],
      outputs: [
        {
          'public': true,
          base_url: base_url,
          filename: 'mp4_' + filename_without_ext + '.mp4',
          label: 'webmp4',
          format: 'mp4',
          audio_codec: 'aac',
          video_codec: 'h264'
        },
        {
          'public': true,
          base_url: base_url,
          filename: 'webm_' + filename_without_ext + '.webm',
          label: 'webwebm',
          format: 'webm',
          audio_codec: 'vorbis',
          video_codec: 'vp8'
        },
        {
          'public': true,
          base_url: base_url,
          filename: 'ogv_' + filename_without_ext + '.ogv',
          label: 'webogv',
          format: 'ogv',
          audio_codec: 'vorbis',
          video_codec: 'theora'
        },
        {
          thumbnails: {
            'public': true,
            base_url: base_url,
            filename: 'thumbnail_' + filename_without_ext,
            times: [4],
            aspect_mode: 'preserve',
            width: '100',
            height: '100'
          }
        }
      ]
    }

    z_response = Zencoder::Job.create(params)

    z_response.body['outputs'].each do |output|
      @model.update_attribute(:zencoder_output_id, output['id']) if output['label'] == 'webmp4'
    end
  end

  def filename_without_ext
    File.basename(@model.file.url, File.extname(@model.file.url))
  end

  def url_for_format(prefix, extension = nil)
    extension ||= prefix
    video_url + '/' + prefix + '_' + filename_without_ext + '.' + extension
  end

  def video_url
    @base_url ||= File.dirname(@model.file.url)
  end
end
