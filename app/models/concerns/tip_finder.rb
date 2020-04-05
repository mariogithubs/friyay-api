module TipFinder
  extend ActiveSupport::Concern

  def viewable_tips(options = {})
    # CURRENTLY THIS IS FARILY COUPLED WITH TOPIC_PREFERENCE
    # user.rb HAS ITS OWN VERSION OF VIEWABLE TIPS

    @topic_tip_ids = topic_tip_followers(options[:topic_ids]).pluck(:follower_id)
    @filtered_tips = filter_tips(Tip.where(id: @topic_tip_ids))
    @filtered_tip_ids = @filtered_tips.pluck(:id)

    tip_id_collection = build_user_following_tips + public_tips + shared_with_following_tips + owned_tips

    # TODO: Guest considerations

    tip_id_collection = tip_id_collection.uniq

    # NOTE: Only use contexts for order, not determining viewabliity
    context_join = 'LEFT JOIN context_tips ON context_tips.tip_id = tips.id'
    context_join += " AND context_tips.context_id = '#{options[:context].try(:id)}'"

    tips = Tip.joins(context_join)
           .select('tips.*, context_tips.position')
           .where('tips.id IN (?)', tip_id_collection)
           .order('context_tips.position')
           .order(created_at: 'DESC')

    tips
  end

  # private

  def filter_tips(tips)
    # THESE FILTER TIPS COUNT ON THIS ONLY BEING USED IN TOPIC PREFERENCES
    # THIS MAY NEED A NEW NAME, ITS A SPECIFIC FILTER ON WHO THE USER HAS CHOSEN TO FOLLOW
    # CURRENTLY, THE DEFAULT FOR EVERY TOPIC IS TO FOLLOW_ALL_USERS
    # TODO: Find a way to clarify the scope of this to TopicPreferences
    return Tip.none if follow_no_users?
    return tips if follow_all_users?
    # return selected_tips(tips) if follow_all_users?
    return selected_tips(tips) if follow_select_users?
    return tips_except_blocked(tips) if block_users?
  end

  def selected_tips(tips)
    tips.where(user_id: user.following_users.pluck(:followable_id))
    # tips.where(user_id: topic.topic_users.show.where(follower_id: user_id).pluck(:id))
  end

  def tips_except_blocked(tips)
    tips.where.not(user_id: topic.topic_users.block.where(follower_id: user_id).pluck(:id))
  end

  def topic_tip_followers(topic_ids)
    topic_ids ||= [topic_id] + topic.descendants.pluck(:id)
    Follow.where(followable_type: 'Topic', follower_type: 'Tip', followable_id: topic_ids)
  end

  # Build a list of tips that the user is following
  # Returns an array of acceptible ids
  def build_user_following_tips
    group_ids = instance_user.follows.where(followable_type: 'Group').pluck(:followable_id)

    following_tip_ids = instance_user.follows.where(id: instance_available_ids).pluck(:followable_id)

    group_tip_ids = Follow.where(
      id: instance_available_ids,
      blocked: false,
      follower_type: 'Group',
      follower_id: group_ids
    ).pluck(:followable_id)

    following_tip_ids + group_tip_ids
  end

  def public_tips
    return [] if user.has_role?(:guest, current_domain)
    return [] if current_domain.tenant_name == 'public'
    @filtered_tips.where(share_public: true).try(:pluck, :id)
  end

  # Build a list of tips that are marked share_following created by
  # users that follow the current_user
  def shared_with_following_tips
    follower_ids = user.user_followers.pluck(:id)

    @filtered_tips.where(share_following: true, user_id: (follower_ids).uniq).pluck(:id)
  end

  def owned_tips
    instance_user.tips.enabled.where(id: @topic_tip_ids).try(:pluck, :id)
  end

  def instance_user
    @user ||= user
  end

  def instance_available_ids
    @available_follow_ids ||= Follow.where(followable_type: 'Tip', followable_id: @filtered_tip_ids).pluck(:id)
  end
end
