class UserDetailSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :first_name, :last_name, :name, :username, :current_domain_role, :is_active, :assigned_views

  has_one :user_profile, serializer: UserProfileSerializer, &:user_profile
  
  has_many :invitations
  has_many :notifications
  has_many :following_tips, &:following_tips
  has_many :following_users, &:following_users
  has_many :following_topics, &:following_topics
  has_many :user_followers, &:user_followers
  has_many :topic_orders
  has_many :user_topic_people_order, &:user_topic_people_order

  
  attribute :is_active do |object, params|
    MembershipService.new(params[:domain], object).active?
  end

  attribute :assigned_views do |object|
    object.assigned_views.map {|av| [av.id, av.name]}
  end

  attribute :current_domain_role do |object, params|
    current_domain = params[:domain]
    'admin' if object.has_role?(:admin, current_domain)
    'guest' if object.guest_of?(current_domain)
    'power' if object.power_of?(current_domain)

    'member'
  end

  has_many :user_topic_label_order, &:user_topic_label_order

end
