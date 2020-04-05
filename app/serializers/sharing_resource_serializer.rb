class SharingResourceSerializer < ActiveModel::Serializer
  attributes :name, :label, :resource_type, :created_at, :slug, :creator_name, :topic_paths

  def resource_type
    return 'users' if object.resource_type == 'domainmembers'
    object.resource_type
  end
end
