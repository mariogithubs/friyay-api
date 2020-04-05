class CardFollowerSerializer
  include FastJsonapi::ObjectSerializer

  attribute :type do |object|
    object.class.model_name.plural
  end
      
  attribute :name do |object|
    "#{object.first_name} #{object.last_name}"
  end
      
  attribute :avatar_url do |object|
    object.user_profile.avatar_thumbnail_url
  end

  attribute :url do |object|
    Rails.application.routes.url_helpers.v2_user_url(object, host: 'api.tiphive.dev')
  end
  
end