class SearchResource
  alias_method :read_attribute_for_serialization, :send

  attr_accessor :id, :name, :label, :resource_type, :created_at, :slug, :creator_name, :topic_paths, :is_disabled

  def initialize(resource_instance)
    @resource_instance = resource_instance
    @id = @resource_instance.id
    @resource_type = @resource_instance.class.to_s.downcase.pluralize
    @slug = @resource_instance.try(:slug) || @id
    build_resource_map
  end

  # private

  def build_resource_map
    creator = User.find_by_id(@resource_instance.user_id) if @resource_instance.respond_to?(:user_id)
    @creator_name = creator.name if creator && @resource_instance.try(:user_id)
    send("#{@resource_instance.class.to_s.underscore}_map")
  end

  def user_map
    self.name = @resource_instance.name
    self.label = 'Member'
  end
  alias_method :domain_member_map, :user_map

  def tip_map
    self.name = @resource_instance.title
    self.label = 'Card'

    topics = @resource_instance.following_topics.to_a
    topics_for_topic_paths = remove_duplicate_topics(topics)

    self.topic_paths = build_topic_paths(topics_for_topic_paths)
    self.created_at = @resource_instance.created_at
    self.is_disabled = @resource_instance.is_disabled
  end

  def topic_map
    self.name = @resource_instance.title
    self.label = build_topic_label
    self.topic_paths = build_topic_paths(@resource_instance)
    self.created_at = @resource_instance.created_at
  end

  def group_map
    self.name = @resource_instance.title
    self.label = @resource_instance.class.to_s
    self.created_at = @resource_instance.created_at
  end

  def build_topic_paths(topics)
    return [] if topics.nil?
    return [] if @resource_instance.try(:root?)

    topics = [topics] unless topics.is_a?(Array)

    topic_paths = []
    topics.each do |topic|
      topic_paths << topic.path.map(&:title)
    end

    topic_paths
  end

  def self.model_name
    @_model_name ||= ActiveModel::Name.new(self)
  end

  def build_topic_label
    return 'SubTopic' if @resource_instance.subtopic?

    'Topic'
  end

  def remove_duplicate_topics(topics)
    root_ids = topics.map(&:ancestry).compact.map { |topic| topic.split('/').first }.map(&:to_i)

    topics.to_a.delete_if { |topic| root_ids.include?(topic.id) }

    topics.uniq
  end
end
