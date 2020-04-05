class QuestionSerializer < ActiveModel::Serializer
  attributes :title, :body, :creator, :created_at

  belongs_to :user
  has_many :topics
  has_many :subtopics
  has_many :comments
  has_many :user_followers
  has_many :list_followers
  has_many :group_followers
  has_many :abilities
  has_many :masks

  def comments
    object.comment_threads
  end

  def creator
    return {} if object.user.blank?
    build_user_json(object.user)
  end

  def masks
    object.masks(scope)
  end

  def abilities
    object.abilities(scope)
  end

  private

  def build_user_json(user)
    {
      id: user.id,
      type: user.class.model_name.plural,
      name: "#{user.first_name} #{user.last_name}",
      avatar: '',
      url: Rails.application.routes.url_helpers.v2_user_url(user, host: 'api.api.dev')
    }
  end
end
