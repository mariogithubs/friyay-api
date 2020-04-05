class UserSerializerAMS < ActiveModel::Serializer
  attributes :first_name, :last_name, :name, :username, :current_domain_role, :is_active

  has_one :user_profile

  # def user_profile
  #   build_profile_json(object.user_profile)
  # end

  def current_domain_role
    domain = current_domain
    return 'admin' if object.has_role?(:admin, domain)
    return 'guest' if object.guest_of?(domain)
    return 'power' if object.power_of?(domain)

    'member'
  end

  # rubocop:disable Style/PredicateName
  # Because the front end wants is_active, not active?
  def is_active
    membership = MembershipService.new(current_domain, object)
    membership.active?
  end
  # rubocop:enable Style/PredicateName

  private

  def build_profile_json(profile)
    {
      avatar_processing: profile.avatar_processing,
      background_image_processing: profile.background_image_processing,
      avatar_url: profile.avatar_square_url,
      background_image_url: profile.background_image_large_url,
      description: profile.description,
      notification_settings: profile.notification_settings,
      follow_all_domain_members: profile.follow_all_domain_members,
      follow_all_topics: profile.follow_all_topics,
      counters: profile.counters
    }
  end

  def current_domain
    Domain.find_by(tenant_name: Apartment::Tenant.current) || Domain.new(tenant_name: 'public')
  end
end