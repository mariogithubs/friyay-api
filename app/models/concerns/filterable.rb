# rubocop:disable ModuleLength
module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filter(filter_params)
      # THIS IS THE KEY TO TIP FILTERING
      # FOR INSTANCE: tips.filter({ title: 'market' }) will find all tips with 'market' somewhere in the title
      return all if filter_params.blank?

      query_statement = all
      # TEEFAN: Talk to Anthony about how we can make this better
      # query_statement = filter_scope(query_statement, filter_params)
      query_statement = filter_columns(query_statement, filter_params)
      query_statement = filter_types(query_statement, filter_params)
      query_statement = filter_labels(query_statement, filter_params)

      query_statement
    end

    def filter_columns(query_statement, filter_params)
      # TODO: Currently this handles all filtering b/c of the default last statement
      # By default intersection of filters is taken
      # Take union if :combine_with is "OR"
      if filter_params[:combine_with] == "OR"
        return take_union(query_statement, filter_params)
      end
      result_statement = query_statement
      filter_params.each do |key, value|
        case key.to_s
        when 'title'
          result_statement = query_statement.where("title ILIKE CONCAT('%', ?, '%')", value)
        when 'name'
          result_statement = query_statement.public_send('domain_name_query', value) if name == 'Domain'
          result_statement = query_statement.public_send('user_name_query', value) if name == 'User'
        when 'topics'
          result_statement = result_statement.public_send(key, value, filter_params)
        else
          # This default filter relies on methods in the Tip model
          # See filters below. Probably a more visible place we can keep these
          # for instance tips.filter({ created_by: 6873 }) would return all tips I created
          if query_statement.respond_to?(key) && value.present?
            result_statement = result_statement.public_send(key, value)
          end
        end
      end

      result_statement
    end

    def take_union(query_statement, filter_params)
      ids = filter_params.flat_map do |key, value|
        if query_statement.respond_to?(key) && value.present?
          query_statement.public_send(key, value)
        end
      end
      return query_statement.where id: ids
    end

    def filter_types(query_statement, filter_params)
      return query_statement if query_statement.nil? || filter_params[:type].blank?
      result_statement = query_statement

      case filter_params[:type]
      when 'latest'
        result_statement = query_statement
                           .where("#{to_s.downcase.pluralize}.created_at > ?", Time.now.utc - 30.days)
      when 'mine'
        result_statement = query_statement
                           .where("#{to_s.downcase.pluralize}.user_id = ?", filter_params[:current_user_id])
      when 'liked'
        result_statement = query_statement
                           .joins(:votes_for)
                           .where(votes: { voter_id: filter_params[:current_user_id], vote_scope: :like })
      when 'starred'
        result_statement = query_statement
                           .joins(:votes_for)
                           .where(votes: { voter_id: filter_params[:current_user_id], vote_scope: :star })
      when 'others_liked'
        result_statement = query_statement
                           .joins(:votes_for)
                           .where('votes.voter_id != ?', filter_params[:current_user_id])
                           .where(votes: { vote_scope: :like })
      end if %w(Tip Topic).include?(name)

      result_statement
    end

    def filter_labels(query_statement, filter_params)
      return query_statement if query_statement.nil? || filter_params[:labels].blank? || %w(Tip).exclude?(name)

      label_ids = filter_params[:labels].to_s.split(',')

      query_statement.joins(:label_assignments).where(label_assignments: { item_type: to_s, label_id: label_ids })
    end

    def filter_with_current_user(current_user, filter_params)
      # ONLY USE WITH USERS CONTROLLER
      # Probably need to refactor and separate topics and users and tips filters
      # Or make them VERY easy to follow
      return all if filter_params.blank?

      case
      when filter_params.key?(:users)
        filter_params = set_filter_defaults(current_user, filter_params)

        scope = user_scope(current_user, filter_params)
        new_params = filter_params.except(:users)
      when filter_params.key?(:topics)
        scope = topic_scope(current_user, filter_params[:topics])
        new_params = filter_params.except(:topics)
      else
        scope = all
        new_params = filter_params
      end

      return scope if new_params.blank?
      scope.active_scope(filter_params).filter(new_params)
    end

    def set_filter_defaults(current_user, filter_params)
      local_current_domain = current_domain
      filter_params[:users] = 'following' if current_user.guest_of?(local_current_domain)
      filter_params[:users] = 'following' if local_current_domain.public_domain?
      filter_params[:is_active] = 'true' unless filter_params.key?(:is_active)

      filter_params
    end

    def user_scope(user, filter_params)
      return filter(filter_params) if filter_params.is_a?(Hash) && filter_params.key?(:name)

      case filter_params[:users]
      when 'not_following'
        following_ids = user.follows.where(followable_type: 'User').pluck(:followable_id)

        scope = where.not(id: following_ids.uniq)
      when 'following'
        scope = joins(:followings)
                .where(follows: { follower_type: 'User', follower_id: user.id })
      when 'followers'
        scope = joins(:follows)
                .where(follows: { followable_type: 'User', followable_id: user.id })
      when 'all'
        scope = all
      else
        # Users following topics I follow who I am not currently following
        following_user_ids = user.follows.where(followable_type: 'User').pluck(:followable_id).uniq
        following_topic_ids = user.follows.where(followable_type: 'Topic').pluck(:followable_id).uniq
        similar_user_followers = Follow.where(
          followable_type: 'Topic',
          followable_id: following_topic_ids,
          follower_type: 'User'
        )

        similar_user_ids = similar_user_followers.pluck(:follower_id).uniq

        scope = where(id: similar_user_ids).where.not(id: following_user_ids).where.not(id: user.id)
      end

      scope
    end

    def active_scope(filter_params)
      return all if current_domain.public_domain?

      case filter_params[:is_active]
      when 'false'
        scope = joins(:domain_memberships)
                .where(domain_memberships: { active: false })
      when 'all'
        scope = joins(:domain_memberships)
                .where('domain_memberships.active = ? OR domain_memberships.active = ?', true, false)
      else
        scope = joins(:domain_memberships)
                .where(domain_memberships: { active: true, domain_id: current_domain.id})
      end

      scope
    end

    def topic_scope(user, filter_params)
      case filter_params
      when 'not_following'
        following_ids = user.follows.where(followable_type: 'Topic').pluck(:followable_id)

        scope = where.not(id: following_ids.uniq)
      else
        scope = all
      end

      scope
    end

    def domain_name_query(value)
      query = "name ILIKE CONCAT('%', ?, '%') OR tenant_name ILIKE CONCAT('%', ? , '%')"
      where(query, value, value)
    end

    def user_name_query(value)
      query = "first_name ILIKE CONCAT('%', ?, '%') OR last_name ILIKE CONCAT('%', ?, '%')"
      query += " OR email ILIKE CONCAT('%', ? , '%')"
      where(query, value, value, value)
    end

    # *****************************************
    # FILTERS: List filters below as methods
    # The idea is that each method is a scope
    # You can write Topic.latest.created_by(user_id).within_group(group_id)
    # Or like shown above query_statement.send(filter_method, value if any)
    # *****************************************
    def latest
      klass = self
      where("#{klass.to_s.downcase.pluralize}.created_at > ?", Time.now.utc - 30.days)
    end

    def created_by(user_id)
      where(user_id: user_id)
    end

    def users(filter_kind)
      case filter_kind
      when 'following'

      when 'followers'
      else
        all
      end
    end

    def topics(filter_kind, filter_params)
      case filter_kind
      when 'following'
        # means topics the user is following
        user = filter_params[:current_user]
        user_following_topic_ids = user.following_topics.select(:followable_id)

        follow_opts = {
          followable_type: 'Topic',
          followable_id: user_following_topic_ids
        }

        scope = joins(:follows).where(follows: follow_opts)
      when 'not_following'
        # means topics the user is not following
        user = filter_params[:current_user]
        user_following_topic_ids = user.following_topics.select(:followable_id)

        follow_opts = {
          followable_type: 'Topic',
          followable_id: user_following_topic_ids
        }

        following_ids = joins(:follows)
                        .where(follows: follow_opts).pluck(:follower_id)

        scope = where.not(id: following_ids)
      else
        scope = all
      end

      scope
    end

    # Teefan - TODO: review alternate *filter_scope* method implementation.
    #                I feel it's not easy to understand the flow below.
    def following_topic(topic_id)
      joins(:follows)
        .where(follows: { followable_type: 'Topic', followable_id: topic_id.to_i })
    end

    def following_group(group_id)
      joins(:follows)
        .where(follows: { followable_type: 'Group', followable_id: group_id.to_i })
    end

    # SCOPE METHODS
    def within_group(group_id)
      return all unless %w(Topic Tip User).include?(name)

      # If we're looking for Topics or tips:
      if %w(Topic Tip).include?(name)
        followable_ids = Follow.where(
          follower_type: 'Group',
          follower_id: group_id,
          followable_type: name
        ).pluck(:followable_id).uniq

        return where(id: followable_ids)
      end

      return all unless %w(User).include?(name)

      # If we're looking for Users
      follower_ids = Follow.where(
        followable_type: 'Group',
        followable_id: group_id,
        follower_type: name
      ).pluck(:follower_id).uniq

      where(id: follower_ids)
    end

    def followed_by_user(user_id)
      # TODO: Ensure user is a member or guest of domain except public
      return all unless %w(Topic Tip).include?(name)

      joins(:followings)
        .where(follows: { follower_type: 'User', follower_id: user_id })
    end

    def not_followed_by_user(user_id)
      return all unless %w(Topic Tip).include?(name)

      followable_ids = Follow.where(
        follower_type: 'User',
        follower_id: user_id,
        followable_type: name
      ).pluck(:followable_id).uniq

      where.not(id: followable_ids)
    end

    def shared_with(user_id)
      return all unless %w(Topic Tip).include?(name)

      resource_ids = ShareSetting.select(:shareable_object_id).where(
        shareable_object_type: name,
        sharing_object_type: 'User',
        sharing_object_id: user_id
      )

      where(id: resource_ids)
    end

    def assigned_to(user_id)
      return all unless %w(Tip).include?(name)

      resource_ids = TipAssignment.select(:tip_id).where(
        assignment_id: user_id, assignment_type: 'User'
      )

      where(id: resource_ids)
    end

    def current_domain
      Domain.find_by(tenant_name: Apartment::Tenant.current) || Domain.new(tenant_name: 'public')
    end

    def filter_tips(params, tips_params, pagesize, current_user)
      tips = tips_params
      tips = tips.joins(:assigned_users)
             .where(tip_assignments: { assignment_id: params[:assignedTo] }) if params[:assignedTo].present?

      tips = tips.where(start_date: params[:start_date]) if params[:start_date].present?
      tips = tips.('start_date >= ?', params[:start_date_from]) if params[:start_date_from].present?
      tips = tips.('start_date <= ?', params[:start_date_to]) if params[:start_date_to].present?

      tips = tips.where(due_date: params[:due_date]) if params[:due_date].present?
      tips = tips.('due_date >= ?', params[:due_date_from]) if params[:due_date_from].present?
      tips = tips.('due_date <= ?', params[:due_date_to]) if params[:due_date_to].present?

      tips = tips.where(completion_date: params[:completion_date]) if params[:completion_date].present?
      tips = tips.('completion_date >= ?', params[:completion_date_from]) if params[:completion_date_from].present?
      tips = tips.('completion_date <= ?', params[:completion_date_to]) if params[:completion_date_to].present?

      tips = tips.joins(:votes_for).where(votes: { voter_id: current_user.id, vote_scope: :star }) if params[:starred_by_user].present?
      tips = tips.joins(:votes_for).where(votes: { voter_id: current_user.id, vote_scope: :like }) if params[:liked_by_user].present?

      topics_following = current_user.following_topics if params[:belong_to_topics_followed_by_user].present?
      tips = tips.joins(:follows).where(follows: {followable_type: "Topic", followable_id: topics_following}) if params[:belong_to_topics_followed_by_user].present?

      tips = tips.order_by_ids(params[:tipIDs]) if params[:tipIDs].present? # && (pagesize.present? && tips.count > pagesize.to_i)

      tips
    end
  end
end

# LIST OF FILTERS WE NEED WHEN REFACTORING:
# tips within topics the user is following
# tips within groups the user is following
# tips within topics within the groups the user is following
# topics within groups the user is following
# scoped tips (latest, mine)
# tips that have been liked and/or starred
# topics that have been liked and/or starred
# tips shared_with a user
# topics shared_with a user ** This may only be current user
# Following and Not Following are used a lot for scoping
# NOTE: when current user we should not allow the user id to come from request

# rubocop:enable ModuleLength
