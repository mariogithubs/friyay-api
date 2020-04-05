class VoteService
  def self.add_vote(user, resource, vote_scope)
    return false unless (%i(like star)).include?(vote_scope)
    # vote_scope one of like, star
    # anything else should raise an error so we know we need to update this
    resource.liked_by(user, vote_scope: vote_scope)

    if resource.vote_registered?
      options = {
        user_id: user.id,
        resource_type: resource.class.name,
        resource_id: resource.id,
        vote_scope: vote_scope
      }

      VoteServiceWorker.perform_in(10.seconds, 'count_and_notify', options)
      true
    else
      false
    end
  end

  def self.remove_vote(user, resource, vote_scope)
    return false unless (%i(like star)).include?(vote_scope)
    # vote_scope one of like, star
    # anything else should raise an error so we know we need to update this
    resource.unliked_by(user, vote_scope: vote_scope)
  end

  def self.count_and_notify(opts = {})
    return if opts == {}
    vote_scope = opts['vote_scope']

    ActiveRecord::Base.transaction do
      user = User.find_by(id: opts['user_id'])
      user.user_profile.increment_counter("total_#{vote_scope.to_s.pluralize}")

      resource = opts['resource_type']
                 .classify
                 .constantize
                 .includes(user: :user_profile)
                 .find_by(id: opts['resource_id'])

      resource.user.user_profile.increment_counter("total_#{vote_scope.to_s.pluralize}_received")

      vote = resource.find_votes_for(voter_id: user.id, vote_scope: vote_scope).last

      next unless vote_scope == 'like'

      resource.notify_like(vote) unless user.id == resource.user_id
    end
  end
end
