class TopicSmallSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :user_id, :created_at, :tips_count,
             :starred_by_current_user, :default_view_id, :ancestry

  has_many :topic_preferences
  has_many :user_followers, serializer: UserSerializerAMS

  def tips_count
    object.tip_followers.count
  end

  def topic_preferences
    topic_preferences = set_topic_preferences

    topic_preferences.collect do |topic_preference|
      build_preference_json(topic_preference) if topic_preference
    end
  end

  def starred_by_current_user
    scope.voted_for?(object, vote_scope: :star)
  end

  private

  def set_topic_preferences
    return [object.topic_preferences.first] if scope.blank?

    topic_preferences = object.topic_preferences.select { |tp| tp.user_id == scope.id }

    return [object.topic_preferences.first] if topic_preferences.blank?

    topic_preferences
  end

  def build_preference_json(topic_preference)
    {
      id: topic_preference.id,
      type: topic_preference.class.model_name.plural,
      background_color_index: topic_preference.background_color_index,
      background_image_url: topic_preference.background_image.large.url,
      share_following: topic_preference.share_following,
      share_public: topic_preference.share_public
    }
  end
end
