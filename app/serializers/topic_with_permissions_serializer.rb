class TopicWithPermissionsSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :user_id, :show_tips_on_parent_topic, :created_at, :path, :kind,
             :starred_by_current_user, :tip_count, :image, :cards_hidden, :parent_id, :default_view_id,
             :ancestry

  has_many :topic_preferences

  def topic_preferences
    topic_preferences = set_topic_preferences

    topic_preferences.collect do |topic_preference|
      build_preference_json(topic_preference) if topic_preference
    end
  end

  has_many :abilities
  has_many :masks

  def path
    object.path.collect do |topic|
      build_ancestor(topic)
    end
  end

  def kind
    object.subtopic? ? 'Subtopic' : 'Hive'
  end

  def starred_by_current_user
    scope.voted_for?(object, vote_scope: :star)
  end

  def tip_count
    object.tip_followers.enabled.count
  end

  def parent_id
    object.ancestry.nil? ? nil : object.ancestry.split('/')[-1]
  end

  private

  def set_topic_preferences
    return [object.topic_preferences.first] if scope.blank?

    topic_preferences = object.topic_preferences.where(user_id: scope.id)

    return [object.topic_preferences.first] if topic_preferences.blank?

    topic_preferences
  end

  def build_preference_json(topic_preference)
    {
      id: topic_preference.id,
      user_id: topic_preference.user_id,
      type: topic_preference.class.model_name.plural,
      background_color_index: topic_preference.background_color_index,
      background_image_url: topic_preference.background_image.large.url,
      share_following: topic_preference.share_following,
      share_public: topic_preference.share_public
    }
  end

  def build_ancestor(topic)
    return nil if topic.blank?

    {
      id: topic.id,
      type: 'topics',
      title: topic.title,
      slug: topic.slug
    }
  end

  def masks
    object.masks(scope)
  end

  def abilities
    object.abilities(scope)
  end
end
