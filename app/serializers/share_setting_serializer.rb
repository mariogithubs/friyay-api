class ShareSettingSerializer
  include FastJsonapi::ObjectSerializer

  set_type :share_settings

  attributes :sharing_object_id

  attribute :sharing_object_type do |object|
    object.sharing_object_type.pluralize.downcase
  end
  
  attribute :sharing_object_name do |object, params|
    (object.sharing_object.try(:name) || object.sharing_object.try(:title))
  end

  attribute :shareable_object_avatar do |object|
    (object.sharing_object.avatar.try(:url) if object.sharing_object.respond_to?(:avatar))
  end
end
