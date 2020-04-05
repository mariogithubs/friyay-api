class ContextSerializer < ActiveModel::Serializer
  attributes :context_uniq_id, :default, :topic_id, :created_at, :name
end
