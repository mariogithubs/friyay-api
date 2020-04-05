class UserProfileSerializer
  include FastJsonapi::ObjectSerializer

  set_type :user_profiles

  attributes :id,
             :avatar_processing,
             :background_image_processing,
             :background_image_url,
             :description,
             :notification_settings,
             :ui_settings,
             :resource_capacity,
             :counters,
             :follow_all_domain_members,
             :follow_all_topics

  belongs_to :user

  attribute :avatar_url do |object|
    object.avatar.square.url
  end

  attribute :background_image_url do |object|
    object.background_image.large.url
  end

end
