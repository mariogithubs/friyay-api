module AttachmentUrl
  extend ActiveSupport::Concern

  def avatar_thumbnail_url
    avatar_processing ? avatar.url : avatar.thumb.url
  end

  def avatar_square_url
    avatar_processing ? avatar.url : avatar.square.url
  end

  def background_image_thumbnail_url
    background_image_processing ? background_image.url : background_image.square.url
  end

  def background_image_large_url
    background_image_processing ? background_image.url : background_image.large.url
  end
end
