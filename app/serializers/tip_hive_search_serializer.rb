class TipHiveSearchSerializer < ActiveModel::Serializer
  def attributes(x)
    data = super

    case object
    when User
    when Tip
      data[:topics] = object.following_topics.map { |topic| build_topic_json(topic) }
    when Topic
    end

    if object.is_a?(User)
      data[:name] = object.name
    else
      data[:title] = object.title
    end

    data
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
      title: topic.root? ? nil : topic.title,
      topic_path_string: topic_path_string,
      url: Rails.application.routes.url_helpers.v2_topic_url(topic, host: 'api.tiphive.dev')
    }
  end

  def build_topic_path(topic)
    return nil if topic.root?
    return "/#{topic.title}" if topic.parent.root?

    "/.../#{topic.title}"
  end
end
