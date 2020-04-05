class VideoSerializer < AttachmentSerializer
  attributes :name, :type, :mp4_url, :ogv_url, :thumbnail_url, :webm_url

  private

  def mp4_url
    name.mp4_url
  end

  def ogv_url
    name.ogv_url
  end

  def webm_url
    name.webm_url
  end

  def thumbnail_url
    name.thumbnail_url
  end
end
