class Ability
  include CanCan::Ability

  def initialize(user, domain, topic = nil)
    # REVIEW: this only works with topics!
    # what about tips? or groups? or labels? or other resources?
    alias_action :read, :create, :update, :destroy, to: :crud

    return unless user

    # Set topic to the root Topic if its a SubTopic
    topic = topic.try(:root)

    permissions = ActivityPermission::DEFAULT_ACCESS_HASH

    # load domain permissions
    if domain.private_domain?
      domain_permissions = domain.permission.with_indifferent_access
      permissions = domain_permissions

      if topic
        permissions = permissions.reject { |key, _value| permissions[key] != {} }
        permissions = topic.permission.merge(permissions)
        permissions[:create_topic] = domain_permissions[:create_topic]
      end

      # to include any permissions not in the topic or domain hash
      permissions = ActivityPermission::DEFAULT_ACCESS_HASH.merge(permissions.deep_symbolize_keys)
    end

    can :manage, User, id: user.id

    can :read,   UserProfile
    can :update, UserProfile, user_id: user.id

    can :update, Domain do |resource|
      domain_admin_or_owner_access?(user, resource)
    end

    return admin_abilities if admin_access?(user, domain, topic)
    return guest_abilities(user, domain, permissions) if user.guest_of?(domain)

    member_abilities(user, domain, permissions)
    power_abilities(user, domain, permissions)

    decor_abilities(user, domain, permissions)
  end

  #############################################
  # ABILITIES DEFINITION START
  #############################################

  def admin_abilities
    can :crud, Topic
    can :crud, Tip
    can :crud, Group

    can :like, Tip

    can :comment, Tip
  end

  def guest_abilities(user, domain, permissions)
    # Note: a guest is not a member, so, they can't have 'roles'
    # Or we can make them a member and change member defaults
    # this would require us to give members a 'member' role, right now if you don't have a role, we assume 'member'
    decor_abilities(user, domain, permissions) # Default to member abilities on this one for now

    # A guest can only see topics shared with them
    can :read, Topic.shared_with(user.id)

    can :read, Tip
    can :read, Group

    cook(user, domain, :create,   Tip,      permissions[:create_tip])
    cook(user, domain, :update,   Tip,      permissions[:edit_tip])
    cook(user, domain, :destroy,  Tip,      permissions[:destroy_tip])

    can :update, Tip do |resource|
      user.has_role?('admin', resource) || user.id == resource.user_id
    end

    can :destroy, Tip do |resource|
      user.has_role?('admin', resource) || user.id == resource.user_id
    end
  end

  def decor_abilities(user, domain, permissions)
    cook(user, domain, :like,     Tip,      permissions[:like_tip])
    cook(user, domain, :comment,  Tip,      permissions[:comment_tip])
  end

  def member_abilities(user, domain, permissions)
    # Hard code all members allow to read Tip, Topic, Group
    # Other code determines if the tip is viewable
    # If the user can see it, they can read it
    cook(user, domain, :read,     Tip,      roles: ['member'])
    cook(user, domain, :read,     Topic,    roles: ['member'])
    cook(user, domain, :read,     Group,    roles: ['member'])

    # The following are set by the front end client to override defaults
    cook(user, domain, :create,   Topic,    permissions[:create_topic])
    cook(user, domain, :update,   Topic,    permissions[:edit_topic])
    cook(user, domain, :destroy,  Topic,    permissions[:destroy_topic])

    cook(user, domain, :create,   Tip,      permissions[:create_tip])
    cook(user, domain, :update,   Tip,      permissions[:edit_tip])
    cook(user, domain, :destroy,  Tip,      permissions[:destroy_tip])

    cook(user, domain, :create,   Group,    permissions[:create_group])
    cook(user, domain, :update,   Group,    permissions[:edit_group])
    cook(user, domain, :destroy,  Group,    permissions[:destroy_group])
    # Future: label, filter, template
  end

  def power_abilities(user, domain, permissions)
    cook(user, domain, :read,     Tip,      roles: ['power'])
    cook(user, domain, :read,     Topic,    roles: ['power'])
    cook(user, domain, :read,     Group,    roles: ['power'])

    # The following are set by the front end client to override defaults
    cook(user, domain, :create,   Topic,    permissions[:create_topic])
    cook(user, domain, :update,   Topic,    permissions[:edit_topic])
    cook(user, domain, :destroy,  Topic,    permissions[:destroy_topic])

    cook(user, domain, :create,   Tip,      permissions[:create_tip])
    cook(user, domain, :update,   Tip,      permissions[:edit_tip])
    cook(user, domain, :destroy,  Tip,      permissions[:destroy_tip])

    cook(user, domain, :create,   Group,    permissions[:create_group])
    cook(user, domain, :update,   Group,    permissions[:edit_group])
    cook(user, domain, :destroy,  Group,    permissions[:destroy_group])
    # Future: label, filter, template
  end

  #############################################
  # ABILITIES DEFINITION END
  #############################################

  #############################################
  # ABILITIES HELPERS START
  #############################################

  def cook(user, domain, action, subject, access)
    if member_access?(access) || power_access?(access)
      can action, subject
    else
      # return if create b/c create won't have a resource to check
      return if [:create].include?(action)

      if domain && domain.public_domain?
        can action, subject do |resource|
          user.id == resource.user_id
        end

        return
      end

      can action, subject do |resource|
        user.has_role?('admin', resource) || user.id == resource.user_id
      end
    end
  end

  def member_access?(access)
    access[:roles] && access[:roles].is_a?(Array) && access[:roles].include?('member')
  end

  def power_access?(access)
    access[:roles] && access[:roles].is_a?(Array) && access[:roles].include?('power')
  end

  def admin_access?(user, domain, topic)
    domain_admin_or_owner_access?(user, domain) || hive_admin_or_owner_access?(user, topic)
  end

  def domain_admin_or_owner_access?(user, domain)
    # there is no admin access defined in public domain, yet?
    return false if !domain || domain.public_domain?

    user.has_role?('admin', domain) || user.id == domain.user_id
  end

  def hive_admin_or_owner_access?(user, topic)
    return false unless topic

    user.has_role?('admin', topic) || user.id == topic.user_id
  end

  #############################################
  # ABILITIES HELPERS END
  #############################################
end
