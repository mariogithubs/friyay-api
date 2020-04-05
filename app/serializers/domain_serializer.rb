class DomainSerializer < ActiveModel::Serializer
  attributes :name,
             :tenant_name,
             :logo_processing,
             :background_image_processing,
             :logo,
             :background,
             :join_type,
             :email_domains,
             :allow_invitation_request,
             :sso_enabled,
             :idp_entity_id,
             :idp_sso_target_url,
             :idp_slo_target_url,
             :issuer,
             :stripe_customer_id,
             :stripe_card_id,
             :user,
             :default_view_id,
             :color

  has_one  :domain_permission
  has_many :roles
  has_many :abilities
  has_many :masks

  def domain_permission
    build_domain_permission_json(object.domain_permission)
  end

  def roles
    build_roles_json(object.users_roles)
  end

  def logo
    object.logo.small.url
  end

  def background
    object.background_image.large.url
  end

  def masks
    {
      is_admin: (scope.has_role? :admin, object),
      is_owner: object.user.present? && object.user == scope,
      is_guest: scope.guest_of?(object),
      is_member: scope.member_of?(object),
      is_power: scope.power_of?(object)
    }
  end

  def abilities
    ability = Ability.new(scope, object)
    {
      topics: {
        can_create: ability.can?(:create, Topic)
      },
      tips: {
        can_create: ability.can?(:create, Tip),
        can_update: ability.can?(:update, Tip)
      },
      groups: {
        can_create: ability.can?(:create, Group),
        can_update: ability.can?(:update, Group)
      }
      # ,
      # questions: {
      #   can_create: ability.can?(:create, Question)
      # }
    }
  end

  private

  def build_domain_permission_json(domain_permission)
    if domain_permission
      {
        id: domain_permission.id,
        access_hash: domain_permission.access_hash
      }
    else
      {
        id: nil,
        access_hash: ActivityPermission::DEFAULT_ACCESS_HASH
      }
    end
  end

  def build_roles_json(users_roles)
    users = User.where(id: users_roles.map(&:user_id)).uniq
    roles = Role.where(id: users_roles.map(&:role_id)).uniq

    users_roles.collect do |users_role|
      role = roles.find { |single_role| single_role.id == users_role.role_id }
      role_user = users.find { |user| user.id == users_role.user_id }

      {
        name: role.name,
        # name: users_role.role_id, # If needed, we may need to figure out why need role_id
        user_id: users_role.user_id,
        user_name: role_user.name
      }
    end.uniq
  end
end
