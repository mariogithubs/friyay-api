class MembershipService
  attr_accessor :domain, :user, :membership

  def initialize(domain, user)
    @domain = domain
    @user = user
    @membership = select_membership

    @membership
  end

  def select_membership
    user.domain_memberships.find_by(domain_id: domain.id, role: 'member') ||
    user.domain_memberships.find_by(domain_id: domain.id, role: 'power') ||
    user.domain_memberships.find_by(domain_id: domain.id, role: 'guest')
  end

  def active?
    return true if domain.public_domain?
    membership.active?
  end

  def join(opts = { as: 'member' })
    opts[:as].downcase!
    return unless domain.is_a?(Domain)
    opts[:as] = 'member' if opts[:as] == 'domain'

    memberships = user
                  .domain_memberships
                  .where(domain: domain)
                  .where(role: opts[:as]).to_a

    if memberships.empty?
      user.domain_memberships.find_or_create_by(
        domain: domain,
        role: opts[:as],
        invitation_id: opts[:invitation_id],
        active: true
      )
    end
    memberships.select { |membership| membership.role == opts[:as] }.each(&:activate!)

    user.add_role(:guest, domain) if opts[:as] == 'guest'

    user.add_role(:power, domain) if opts[:as] == 'power'

    memberships.first
  end

  def leave(opts = { as: 'member' })
    return unless domain.is_a?(Domain)

    memberships = user.domain_memberships.where(domain_id: domain.id).to_a

    memberships.select { |membership| membership.role == opts[:as] }.each(&:deactivate!)
  end

  # leave! deactivates and removes associations
  def leave!
    leave(as: 'member')
    leave(as: 'guest')
    leave(as: 'power')

    remove_membership_associations
  end

  # completely remove all traces of user on domain
  def destroy!(opts = { as: %w(member guest power) })
    return unless domain.is_a?(Domain)

    if opts[:as].is_a?(Array)
      member_types = opts[:as] if opts[:as].is_a?(Array)
    else
      member_types = [opts[:as]]
    end

    remove_membership_associations if member_types == %w(member guest power)

    member_types.each do |member_type|
      memberships = user.domain_memberships.where(domain_id: domain.id).to_a
      memberships.select { |membership| membership.role == member_type }.each(&:destroy)
    end
  end

  def remove_membership_associations
    Apartment::Tenant.switch domain.tenant_name do
      # follows.destroy_all
      Invitation.where(email: user.email).destroy_all
      user.notifications.destroy_all
      # user_permissions.destroy_all
      user.share_settings.destroy_all
      # tip_assignments.destroy_all

      Role::TYPES.each do |role_type|
        user.remove_role(role_type.to_sym, domain)
      end

      # Remove from Search index
      Sunspot.remove(user)
    end
  end
end
