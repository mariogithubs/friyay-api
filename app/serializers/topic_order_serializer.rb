class TopicOrderSerializer < ActiveModel::Serializer
  attributes :name, :subtopic_order, :tip_order, :topic_id, :is_default

  belongs_to :topic
  has_many :users, serializer: UserSerializerAMS

end
