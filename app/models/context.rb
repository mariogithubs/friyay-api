# == Schema Information
#
# Table name: contexts
#
#  context_uniq_id :string           not null, primary key, indexed
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#  default         :boolean          default(FALSE)
#  topic_id        :integer
#

# == Description
# - Only use contexts for order, not determining viewabliity
# - Keys are optional, except user, since these are user specific orders
# - The uniq id key order must be user:domain:group:topic

class Context < ActiveRecord::Base
  self.primary_key = 'context_uniq_id'

  TEMPLATE_KEYS = %w( user domain group topic tip )

  belongs_to :topic
  has_many :context_tips
  has_many :tips, through: :context_tips
  has_many :context_topics
  has_many :topics, through: :context_topics

  validates :context_uniq_id, uniqueness: true

  before_create :assign_topic_id, :ensure_default, :assign_name

  def self.generate_id(resource_hash)
    context_id = ''

    TEMPLATE_KEYS.each do |key|
      value = resource_hash.with_indifferent_access[key]
      next if value.blank? || value.to_i < 1
      context_id = add_path(context_id, key, value)
    end

    context_id
  end

  def self.add_path(context_id, path_type, path_id = nil)
    path = path_id.present? ? [path_type, path_id].join(':') : nil

    [context_id, path].compact.reject(&:empty?).join(':')
  end

  def self.current_or_default(context_id)
    topic_id = context_id[/:topic:([0-9]+)/, 1]
    default = where("context_uniq_id LIKE '%topic:#{topic_id}'").find_by(default: true)

    find_by(context_uniq_id: context_id) || default
  end

  # TODO: test just this method
  # do a performance test to see if we can find a way to do multiple reorders at once
  def reorder(resource, position)
    kind = resource.class.name.downcase.singularize # tip or topic

    case kind
    when 'tip'
      context_resource = context_tips.find_or_create_by(tip_id: resource.id)
    when 'topic'
      context_resource = context_topics.find_or_create_by(topic_id: resource.id)
    else
      return
    end

    context_resource.insert_at(position.to_i)
  end

  private

  def assign_topic_id
    self.topic_id = context_uniq_id[/:topic:([0-9]+)/, 1].to_i
  end

  def assign_name
    return unless name.blank?
    self.name = User.find_by(id: context_uniq_id[/user:([0-9]+)/, 1].to_i).name
  end

  def find_default_for_topic
    topic_id = context_uniq_id[/:topic:([0-9]+)/, 1]

    Context.where("context_uniq_id LIKE '%topic:#{topic_id}'").find_by(default: true)
  end

  def ensure_default
    self.default = true unless find_default_for_topic
  end
end
