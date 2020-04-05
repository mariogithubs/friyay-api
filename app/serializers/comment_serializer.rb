class CommentSerializer < ActiveModel::Serializer
  attributes :commentable_id, :commentable_type, :title, :body, :user, :created_at

  has_many :replies

  def replies
    object.children
  end

  def user
    user = object.user
    profile = user.user_profile
    {
      id: user.id,
      type: user.class.model_name.plural,
      name: "#{user.first_name} #{user.last_name}",
      avatar_url: profile.avatar_thumbnail_url,
      url: Rails.application.routes.url_helpers.v2_user_url(user, host: 'api.tiphive.dev')
    }
  end
end
