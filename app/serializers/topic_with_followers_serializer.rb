class TopicWithFollowersSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :user_id, :show_tips_on_parent_topic, :created_at, :path, :kind,
             :starred_by_current_user, :tip_count, :image, :cards_hidden

  has_many :user_followers, serializer: UserSerializerAMS
  has_many :group_followers

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

  private

  def build_ancestor(topic)
    return nil if topic.blank?

    {
      id: topic.id,
      type: 'topics',
      title: topic.title,
      slug: topic.slug
    }
  end
end
