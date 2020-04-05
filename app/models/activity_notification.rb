# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  notifier_id     :integer
#  type            :string
#  action          :string
#  notifiable_type :string           indexed => [notifiable_id]
#  notifiable_id   :integer          indexed => [notifiable_type]
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email_sent_at   :datetime
#  read_at         :datetime
#  is_processed    :boolean          default(FALSE)
#  frequency       :string
#  send_email      :boolean          default(TRUE)
#  invitation_id   :integer          indexed
#

# This will create a Notification, which after_create will
# :enqueue_email, which will send or create a job for later

class ActivityNotification < Notification
  def self.welcome(resource, _opts = {})
    trigger('welcome', resource, resource)
  end

  def self.sso_welcome(resource, _opts = {})
    trigger('sso_welcome', resource, resource)
  end

  def self.someone_followed_you(resource, opts = {})
    trigger('someone_followed_you', resource, resource.follower, opts)
  end

  def self.someone_likes_tip(resource, _opts = {})
    trigger('someone_likes_tip', resource, resource.voter)
  end

  def self.someone_likes_question(resource, _opts = {})
    trigger('someone_likes_question', resource, resource.voter)
  end

  def self.someone_adds_topic(resource, _opts = {})
    return if current_domain.public_domain?

    trigger('someone_adds_topic', resource, resource.user)
  end

  def someone_adds_tip(resource, _opts = {})
    trigger('someone_adds_tip', resource, resource.user)
  end

  def self.someone_add_tip_to_topic(resource, _opts = {})
    trigger('someone_add_tip_to_topic', resource, resource.follower.user)
    # generate_feed_records(resource)  # Tip Feed
  end

  def self.someone_shared_question_with_me(resource, _opts = {})
    trigger('someone_shared_question_with_me', resource, resource.user)
  end

  def self.someone_shared_topic_with_me(resource, _opts = {})
    trigger('someone_shared_topic_with_me', resource, resource.user)
  end

  def self.someone_shared_tip_with_me(resource, _opts = {})
    trigger('someone_shared_tip_with_me', resource, resource.user)
  end

  def self.someone_answered_your_question(resource, _opts = {})
    trigger('someone_answered_your_question', resource, resource.user)
  end

  def self.someone_comments_on_tip(resource, opts = {})
    trigger('someone_comments_on_tip', resource, resource.user)

    # We want to exclude mentioned_users b/c they will already get an email
    opts[:exclude_users] = resource.mentioned_users

    trigger('someone_commented_on_tip_user_commented', resource, resource.user, opts)
  end

  # def self.someone_added_to_group(resource)
  #   trigger('someone_added_to_group', resource, resource.user)
  # end

  def self.someone_added_to_domain(resource, _opts = {})
    trigger('someone_added_to_domain', resource, resource.domain.user)
  end

  def self.someone_joins_domain(resource, _opts = {})
    trigger('someone_joins_domain', resource, resource.user)
  end

  def self.someone_joins_domain_as_guest(resource, _opts = {})
    # resource = domain_membership, resource.user = guest
    # notifier = guest, notifiable = domain_membership
    trigger('someone_joins_domain_as_guest', resource, resource.user)
  end

  def self.follow_a_group(resource, _opts = {})
    trigger('follow_a_group', resource, resource.followable.user)
  end

  def self.add_a_domain(resource, _opts = {})
    trigger('add_a_domain', resource, resource.user)
  end

  def self.join_a_domain(resource, _opts = {})
    trigger('join_a_domain', resource, resource.user)
  end

  def self.someone_commented_on_tip_user_commented(resource, _opts = {})
    trigger('someone_commented_on_tip_user_commented', resource, resource.user)
  end

  def self.someone_assigned_tip(resource, _opts = {})
    trigger('someone_assigned_tip', resource, resource.assignment)
  end

  def self.hive_removed(resource, opts = {})
    recipients = User.where('id in (?)', opts['user_ids'])

    recipients.each do |recipient|
      ActivityNotification.create(
        user: recipient,
        action: 'hive_removed',
        notifier: resource,
        notifiable: resource,
        custom_opts: {
          removed_hive_title: opts['removed_hive_title'],
          alternate_hive_id: opts['alternate_hive_id']
        }
      )
    end
  end

  def self.someone_mentioned_on_comment(resource, _opts = {})
    recipients = get_recipients('someone_mentioned_on_comment', resource)
    recipients = exclude_old_users(recipients) unless current_domain.tenant_name == 'public'
    containing_resource_creator_id = resource.mentionable.commentable.user_id

    recipients.each do |recipient|
      Rails.logger.info("\n\n***** recipient == creator!! ******\n\n") if recipient.id == containing_resource_creator_id
      next if recipient.id == containing_resource_creator_id

      ActivityNotification.create(
        user: recipient,
        action: 'someone_mentioned_on_comment',
        notifier: resource.mentionable.user,
        notifiable: resource.mentionable
      )
    end
  end

  def self.trigger(action_name, resource, notifier, opts = {})
    recipients = get_recipients(action_name, resource, opts)
    recipients = exclude_old_users(recipients) unless current_domain.tenant_name == 'public'

    recipients.each do |recipient|
      activity_notification = ActivityNotification.create(
        user: recipient,
        action: action_name,
        notifier: notifier,
        notifiable: resource,
        send_email: (opts[:send_email] ? opts[:send_email] : true)
      )

      push(action_name, activity_notification)
    end
  end

  def self.push(action_name, activity_notification)
    return if Rails.env == 'test'
    activity_channel = "#{current_domain.tenant_name}-activities"
    serialized_notification = ActiveModel::SerializableResource.new(activity_notification)
    # We don't want notification to be recreated if pusher fails
    Pusher.trigger(activity_channel, action_name, notification: serialized_notification) rescue nil
  end

  def self.generate_feed_records(resource)
    recipients = get_recipients('tip_feed', resource)
    recipients = exclude_old_users(recipients) unless current_domain.tenant_name == 'public'

    recipients.each do |recipient|
      ActivityNotification.create(
        user: recipient,
        action: 'tip_feed',
        notifier: resource.follower.user,
        notifiable: resource.follower
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.get_recipients(action_name, resource, opts = {})
    case action_name
    when 'someone_likes_tip', 'someone_likes_question'
      [resource.votable.user]
    when 'someone_followed_you'
      [resource.followable]
    when 'someone_add_tip_to_topic', 'tip_feed'
      all_followers(resource)
    when 'someone_answered_your_question', 'someone_comments_on_tip'
      [resource.commentable.user] - [resource.user]
    when 'someone_added_to_domain', 'someone_joins_domain'
      resource.domain.users - [resource.domain.user]
    when 'someone_joins_domain_as_guest'
      [resource.try(:invitation).try(:user)].compact
    when 'follow_a_group'
      [resource.follower]
    when 'someone_shared_tip_with_me', 'someone_shared_topic_with_me', 'someone_shared_question_with_me'
      [resource.sharing_object]
    when 'welcome', 'sso_welcome'
      [resource]
    when 'someone_adds_tip'
      [resource.user.following_users] - [resource.user]
    when 'someone_assigned_tip'
      resource.tip.assigned_users
    when 'someone_adds_topic'
      current_domain.domain_members.active.distinct - [resource.user]
    when 'someone_commented_on_tip_user_commented'
      recipients = (resource.commentable.commenters.uniq) - [resource.commentable.user]
      recipients -= [resource.user]
      recipients -= opts[:exclude_users] if opts.key?(:exclude_users)
      recipients  
    else
      [resource.user]
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.all_followers(resource)
    # resource = follow instance
    # Followers of the Topic + Followers of the creator of the Tip - the Creator of the Tip - the Creator of the Topic
    topic_followers = resource.followable.user_followers
    tip_creator_followers = resource.follower.user.user_followers
    tip_creator = resource.follower.user
    topic_creator = resource.followable.user

    recipients = (topic_followers + tip_creator_followers) - [tip_creator] - [topic_creator]

    recipients_allowed_to_view(resource.follower, recipients).uniq
  end

  def self.exclude_old_users(recipients)
    active_users = current_domain.domain_members.active.pluck(:id)
    filtered_recipients = recipients.to_a.delete_if { |recipient| active_users.include?(recipient.id) == false }
    filtered_recipients
  end  

  def self.current_domain
    Domain.find_by(tenant_name: Apartment::Tenant.current) ||
      Domain.new(tenant_name: 'public', join_type: 'open')
  end

  def self.recipients_allowed_to_view(tip, recipients)
    recipients.delete_if { |recipient| tip.viewable_by?(recipient) == false }
  end
end
