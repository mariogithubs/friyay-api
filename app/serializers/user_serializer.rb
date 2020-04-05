class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :first_name, :last_name, :name, :username

  has_one :user_profile, &:user_profile

  attribute :current_domain_role do |object, params|
    domain = params[:domain]
    object.has_role?(:admin, domain) ? 'admin' : (
    object.guest_of?(domain) ? 'guest' : (
    object.power_of?(domain) ? 'power' : 'member'))
  end

  attribute :is_active do |object, params|
    MembershipService.new(params[:domain], object).active?
  end

end
