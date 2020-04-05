class FollowObserver < ActiveRecord::Observer
  def after_create(follow)
    send("#{follow.follower_type.underscore}_follow_#{follow.followable_type.underscore}_after_create", follow)
  rescue
    return false
  end

  def after_destroy(follow)
    send("#{follow.follower_type.underscore}_follow_#{follow.followable_type.underscore}_after_destroy", follow)
  rescue
    return false
  end

  # CREATE Callbacks
  def tip_follow_topic_after_create(follow)
    if follow.followable_type == "Topic" && follow.follower_type == "Tip"
      text = "New card added in Topic-`#{follow.followable.title}`"
      topic_connections = SlackTopicConnection.where(topic_id: ["All Topics",follow.followable.id])
      topic_connections = topic_connections.to_a.uniq(&:slack_channel_id)
      topic_connections.each do |tc|
        tc.post_to_slack_channel(follow.follower, follow.followable, text)
      end
    end
    NotificationWorker.perform_in(1.second, 'someone_add_tip_to_topic', follow.id, follow.class.to_s)
  end

  def tip_follow_tip_after_create(follow)
    # need to make all user followers from parent follow this one

    parent = follow.followable
    parent_share_settings = parent.share_settings
    child = follow.follower
    parent_user_followers = parent.user_followers

    parent_user_followers.each do |user|
      user.follow(child)
    end

    parent_share_settings.each do |share_setting|
      new_share_setting = share_setting.dup
      new_share_setting.shareable_object_id = child.id

      new_share_setting.save
    end
  end

  def user_follow_topic_after_create(follow)
    # START HERE: NOTE: this is not related to moving subtopics, its a different issue
    # this is to make sure that when you follow a Topic, you follow all its subtopics
    # so that Cards assigned only to a Subtopic show up in the Card Feed
    # START HERE WHAT TO DO WITH BULK ACTIONS WE DON'T WANT THIS TO RUN FOR EVERY FOLLOW
    # WE WANT TO INCREMENT COUNTS FOR INSTANCE, JUST ONCE
    # ALSO THINK ABOUT MOVING TOPIC PREFS TO THE FOLLOW MODEL
    # TODO: try this without database access
    topic = follow.followable
    user = follow.follower

    topic.children.each do |subtopic|
      user.follow(subtopic)
    end

    topic.ensure_topic_preference_for(user)
    user.user_profile.increment_counter('total_following_topics')
  end

  def user_follow_user_after_create(follow)
    follow.followable.user_profile.increment_counter('total_user_followers')

    NotificationWorker.perform_in(
      90.seconds,
      'someone_followed_you',
      follow.id,
      follow.class.to_s
    )
  end

  # DESTROY Callbacks
  def user_follow_topic_after_destroy(follow)
    topic = follow.try(:followable)
    user = follow.try(:follower)

    return unless user
    user.user_profile.decrement_counter('total_following_topics') if user

    return unless topic
    topic.children.each do |subtopic|
      user.stop_following(subtopic)
    end

    topic.topic_preferences.for_user(user).destroy
  end

  def user_follow_user_after_destroy(follow)
    follow.followable.user_profile.decrement_counter('total_user_followers')
  end
end
