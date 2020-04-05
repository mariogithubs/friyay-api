class TopicPreferencesSerializer < ActiveModel::Serializer
  attributes :user_id, :background_color_index, :background_image_url,
             :share_public, :share_following,
             :background_image_processing, :background_image_thumbnail_url, :link_option, :link_password

  belongs_to :topic

  def background_image_url
    object.background_image.large.url
  end
end
