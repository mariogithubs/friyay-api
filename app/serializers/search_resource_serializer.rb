class SearchResourceSerializer < ActiveModel::Serializer
  attributes :name, :label, :resource_type, :created_at, :slug, :creator_name, :topic_paths
end
