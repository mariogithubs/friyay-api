class GroupDetailSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :color_index, :user_followers_count, :topic_followers_count

  belongs_to :user, serializer: UserSerializerAMS
  has_many :user_followers
  has_many :topics
  has_many :subtopics

  def topics
    object.following_topics.collect do |topic|
      build_topic_json(topic)
    end
  end

  def subtopics
    subtopic_list = object.subtopics.collect do |subtopic|
      build_topic_json(subtopic)
    end

    subtopic_list.sort_by { |subtopic| subtopic[:hive] }
  end

  def user_followers
    object.user_followers.collect do |user|
      build_user_json(user)
    end
  end

  def user_followers_count
    object.count_user_followers
  end

  def topic_followers_count
    object.count_topic_followers
  end

  private

  def build_topic_json(topic)
    topic_path_string = build_topic_path(topic)
    hive = topic.root

    {
      id: topic.id.to_s,
      slug: topic.slug,
      type: topic.class.model_name.plural,
      hive: hive.title,
      hive_slug: hive.slug,
      hive_url: Rails.application.routes.url_helpers.v2_topic_url(topic.root, host: 'api.tiphive.dev'),
      # Teefan: why don't we return title for root topics?
      # title: topic.root? ? nil : topic.title,
      title: topic.title,
      topic_path_string: topic_path_string,
      url: Rails.application.routes.url_helpers.v2_topic_url(topic, host: 'api.tiphive.dev')
    }
  end

  def build_user_json(user)
    {
      id: user.id,
      name: user.name
    }
  end

  def build_topic_path(topic)
    return nil if topic.root?
    return "/#{topic.title}" if topic.parent.root?

    "/.../#{topic.title}"
  end
end
