class UserAuthenticatedSerializer
  include FastJsonapi::ObjectSerializer
  attributes :email, :first_name, :last_name, :name, :username, :auth_token

  attribute :ui_settings do |object|
    object.user_profile.ui_settings
  end

  attribute :notification_settings do |object|
    object.user_profile.notification_settings
  end

  has_one :user_profile, serializer: UserProfileSerializer, &:user_profile
  has_many :invitations
  has_many :notifications
  has_many :following_tips, &:following_tips
  has_many :following_users, &:following_users
  has_many :user_followers, &:user_followers
  has_many :topic_orders
  has_many :user_topic_label_order, &:user_topic_label_order
  has_many :user_topic_people_order, &:user_topic_people_order

  private

  def build_profile_json(profile)
    {
      id: profile.id,
      avatar_processing: profile.avatar_processing,
      background_image_processing: profile.background_image_processing,
      avatar_url: profile.avatar_square_url,
      background_image_url: profile.background_image_large_url,
      description: profile.description,
      notification_settings: profile.notification_settings,
      follow_all_domain_members: profile.follow_all_domain_members,
      follow_all_topics: profile.follow_all_topics,
      ui_settings: profile.ui_settings,
      resource_capacity: profile.resource_capacity
    }
  end

  def build_user_topic_label_order(order)
    {
      user_id: order.user_id.to_s,
      topic_id: order.topic_id.to_s,
      label_order_id: order.label_order_id.to_s
    }
  end

  def build_user_topic_people_order(order)
    {
      user_id: order.user_id.to_s,
      topic_id: order.topic_id.to_s,
      people_order_id: order.people_order_id.to_s
    }
  end
end
