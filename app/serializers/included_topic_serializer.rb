class IncludedTopicSerializer
  include FastJsonapi::ObjectSerializer

  set_type :topics

  attributes :slug, :title, :parent_id, :ancestry

  attribute :type do |object|
    object.class.model_name.plural
  end
     
  attribute :hive do |object|
    object.root.title
  end
  
  attribute :hive_slug do |object|
    object.root.slug
  end
  
  attribute :hive_url do |object|
    Rails.application.routes.url_helpers.v2_topic_url(object.root, host: 'api.tiphive.dev')
  end

  attribute :url do |object|
    Rails.application.routes.url_helpers.v2_topic_url(object, host: 'api.tiphive.dev')
  end

  
  attribute :topic_path_string do |object|
    object.root? ? nil : (object.parent.root? ? "#{object.title}" : "/.../#{object.title}")
  end

end
