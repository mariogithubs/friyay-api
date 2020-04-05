class ZencoderCallbackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    VideoEncodedWorker.perform_async(params)
    render nothing: true
  end
end
