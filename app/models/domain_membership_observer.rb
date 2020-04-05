class DomainMembershipObserver < ActiveRecord::Observer
  def after_create(domain_membership)
    # TODO: If we add this back, we need a way to differ b/t this and joining
    # NotificationWorker.perform_in(
    #   10.seconds,
    #   'someone_added_to_domain',
    #   domain_membership.id,
    #   domain_membership.class.to_s
    # )

    domain = domain_membership.domain

    Apartment::Tenant.switch domain.tenant_name do
      user = domain_membership.user
      user_profile = user.user_profile

      # Make sure to index the domain member when they join
      # domain_member = DomainMember.find(user.id)
      Sunspot.index! [user]

      notify_guest(domain_membership) && return if domain_membership.role == 'guest'

      # if this domain membership has an invitation, then based on the options
      # we need to follow the selected topics, groups and members
      user_profile.follow_all_topics!
      user_profile.follow_all_domain_members!

      NotificationWorker.perform_in(
        10.seconds,
        'someone_joins_domain',
        domain_membership.id,
        domain_membership.class.to_s
      )

      return if domain.creator?(user)
      NotificationWorker.perform_in(
        45.seconds,
        'join_a_domain',
        domain_membership.id,
        domain_membership.class.to_s
      )
    end
  end

  def notify_guest(domain_membership)
    NotificationWorker.perform_in(
      10.seconds,
      'someone_joins_domain_as_guest',
      domain_membership.id,
      domain_membership.class.to_s
    )
  end
end
