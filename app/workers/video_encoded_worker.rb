class VideoEncodedWorker
  include Sidekiq::Worker

  def perform(zencoder_response)
    zencoder_response['outputs'].each do |output|
      next unless output['label'] == 'webmp4'

      output_id = output['id']
      job_state = output['state']

      video = Video.find_by_zencoder_output_id(output_id)
      video.update_attribute(:zencoder_processed, true) if job_state == 'finished' && video
    end
  end
end
