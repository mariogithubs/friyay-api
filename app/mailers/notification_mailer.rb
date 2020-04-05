class NotificationMailer < ApplicationMailer
  add_template_helper(EmailsHelper)

  default from: "Friyay <#{ENV['TIPHIVE_EMAIL_ADMIN']}>"

  def welcome(notification_id, _opts = {})
    @notification = Notification.find_by_id(notification_id)
    @domain = current_domain
    return unless @notification

    mail(
      subject:  'Congrats! You have created your Friyay account.',
      to:       @notification.user.email
    )
  end

  def sso_welcome(notification_id, _opts = {})
    @notification = Notification.find_by_id(notification_id)
    @domain = current_domain
    return unless @notification

    mail(
      subject:  'Since you had created account via Ping blah blah blah.',
      to:       @notification.user.email
    )
  end

  def someone_likes_tip(notification_id, _opts = {})
    @notification = Notification.find_by_id(notification_id)
    return unless @notification

    @tip = @notification.notifiable.votable
    @domain = current_domain

    mail(
      subject:  'Someone just liked your Card',
      to:       @notification.user.email
    )
  end

  def someone_likes_question(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification

    @question = @notification.notifiable.votable

    mail(
      subject:  'Someone just liked your question',
      to:       @notification.user.email
    )
  end

  def someone_followed_you(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @follower = @notification.notifier
    @domain = current_domain
    return unless @notification
    mail(
      subject:  'You have a new follower on Friyay',
      to:       @notification.user.email
    )
  end

  def someone_adds_topic(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @topic = @notification.notifiable
    mail(
      subject:  "#{@notification.notifier.name} just added a topic to #{@domain.tenant_name}",
      to:       @notification.user.email
    )
  end

  def someone_adds_tip(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @tip = @notification.notifiable
    mail(
      subject:  "#{@notification.notifier.name} just added a Card",
      to:       @notification.user.email
    )
  end

  def someone_assigned_tip(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @tip = @notification.notifiable.tip
    mail(
      subject:  "#{@notification.notifier.name} just assigned a Card",
      to:       @notification.user.email
    )
  end

  def someone_add_tip_to_topic(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @topic = @notification.notifiable.followable
    @tip = @notification.notifiable.follower
    mail(
      subject:  "#{@notification.notifier.name} just added a Card to #{@topic.title}",
      to:       @notification.user.email
    )
  end

  def someone_comments_on_tip(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification

    @tip = @notification.notifiable.commentable

    mail(
      subject:  "Someone just commented on your Card: #{@notification.notifiable.commentable.title}",
      to:       @notification.user.email,
      reply_to: "comment-#{@notification.notifiable.message_identifier}@parse.friyay.io"
    )
  end

  def someone_commented_on_tip(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification

    @tip = @notification.notifiable.commentable

    mail(
      subject:  "Someone just commented on a Card you commented on: #{@notification.notifiable.commentable.title}",
      to:       @notification.user.email,
      reply_to: "comment-#{@notification.notifiable.message_identifier}@parse.friyay.io"
    )
  end

  def follow_a_group(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @group = @notification.notifiable.followable

    mail(
      subject:  "Someone just added you to the team: #{@group.title}",
      to:       @notification.user.email
    )
  end

  def add_a_domain(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = @notification.notifiable
    return unless @notification

    mail(
      subject:  'Easy steps to make Friyay a success at your company.',
      to:       @notification.user.email
    )
  end

  def someone_answered_your_question(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @answer = @notification.notifiable
    @question = @notification.notifiable.commentable

    mail(
      subject:  "Someone answered your question #{@question.title}",
      to:       @notification.user.email
    )
  end

  def someone_shared_question_with_me(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification
    @question = @notification.notifiable.shareable_object

    mail(
      subject:  "#{@notification.notifier.name} just asked you a question",
      to:       @notification.user.email
    )
  end

  def someone_shared_topic_with_me(notification_id, _opts = {})
    @notification = Notification.find(notification_id)

    @domain = current_domain
    return unless @notification
    @topic = @notification.notifiable.shareable_object

    mail(
      subject:  "#{@notification.notifier.name} just shared a Topic with you",
      to:       @notification.user.email
    )
  end

  def someone_shared_tip_with_me(notification_id, _opts = {})
    # Need a list of hives tip is in
    @notification = Notification.find(notification_id)

    @domain = current_domain
    return unless @notification
    @tip = @notification.notifiable.shareable_object
    @hive_titles = @tip.following_topics.without_root.map(&:title)

    mail(
      subject:  "#{@notification.notifier.name} just shared a Card with you",
      to:       @notification.user.email
    )
  end

  def someone_added_to_domain(notification_id, _opts = {})
    @notification = Notification.find(notification_id)

    @domain = current_domain
    return unless @notification
    @new_domain = @notification.notifiable.domain

    mail(
      subject:  "#{@notification.notifier.name} just added a new member to the #{@new_domain.name} workspace",
      to:       @notification.user.email
    )
  end

  def someone_joins_domain(notification_id, _opts = {})
    @notification = Notification.find(notification_id)

    @domain = current_domain
    return unless @notification
    @new_domain = @notification.notifiable.domain

    mail(
      subject:  "#{@notification.notifier.name} just joined the #{@new_domain.name} Workspace",
      to:       @notification.user.email
    )
  end

  def someone_commented_on_tip_user_commented(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain
    return unless @notification

    @tip = @notification.notifiable.commentable

    mail(
      subject:  "Someone just commented on a Card you commented on: #{@notification.notifiable.commentable.title}",
      to:       @notification.user.email,
      reply_to: "comment-#{@notification.notifiable.message_identifier}@parse.friyay.io"
    )
  end

  # START HERE: Attempt to get this email to work
  # Ask madiken to make a send_mail for it
  # then do the same for join_a_domain with instructions for the guest
  # with an explanation of the benefits/restrictions
  def someone_joins_domain_as_guest(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    return unless @notification

    @guest = @notification.notifier
    @recipient = @notification.user
    @domain = current_domain
    @new_domain = @notification.notifiable.domain

    mail(
      subject:  "#{@guest.name} just joined the #{@new_domain.name} workspace as a guest",
      to:       @recipient.email
    )
  end

  def join_a_domain(_notification_id, _opts = {})
    # return
    # @notification = Notification.find(notification_id)

    # @domain = current_domain
    # return unless @notification
    # @new_domain = @notification.notifiable.domain

    # mail(
    #   subject:  "You have successfully joined the #{@new_domain.name} domain on Friyay",
    #   to:       @notification.user.email
    # )
  end

  def hive_removed(notification_id, opts = {})
    @notification = Notification.find(notification_id)
    @notifier = @notification.notifier
    @domain = current_domain
    @removed_hive_title = opts['removed_hive_title']
    @alternate_hive = Topic.find(opts['alternate_hive_id']) if opts['alternate_hive_id']
    return unless @notification

    mail(
      subject:  "Smart card removed",
      to:       @notification.user.email
    )
  end

  # def someone_mentioned(notification_id, opts = {})
  #   @notification = Notification.find(notification_id)
  #   @notifier = @notification.notifier
  #   @domain = current_domain
  #   @removed_hive_title = opts['removed_hive_title']
  #   @alternate_hive = Topic.find(opts['alternate_hive_id']) if opts['alternate_hive_id']
  #   return unless @notification

  #   mail(
  #     subject:  @message,
  #     to:       @notification.user.email
  #   )
  # end

  def daily_feed_email(params, _opts = {})
    email            = params['email']
    notification_ids = params['notification_ids']

    @domain = current_domain
    @host_options = { host: @domain.host_url, protocol: 'https' }

    @notifications = Notification.where('id in (?)', notification_ids)

    mail(
      subject:  'Daily Friyay Summary',
      to:       email
    )
  end

  def weekly_feed_email(params, _opts = {})
    email            = params['email']
    notification_ids = params['notification_ids']

    @domain = current_domain
    @host_options = { host: @domain.host_url, protocol: 'https' }

    @notifications = Notification.where('id in (?)', notification_ids)

    mail(
      subject:  'Weekly Friyay Summary',
      to:       email
    )
  end

  def tip_feed(params, _opts = {})
    email            = params['email']
    notification_ids = params['notification_ids']
    @domain = current_domain
    @notifications = Notification.where('id in (?)', notification_ids)

    mail(subject: 'Friyay Summary', to: email)
  end

  def will_expire(tip_id)
    @domain = current_domain
    @tip = Tip.find_by_id(tip_id)
    return unless @tip

    mail(subject: 'Your Card will expire soon and be archived', to: @tip.user.email)
  end

  def expire(tip_id)
    @domain = current_domain
    @tip = Tip.find_by_id(tip_id)

    return unless @tip

    mail(subject: 'Your Card has been archived', to: @tip.user.email)
  end

  def reminder(notification_id, _opts = {})
    @notification = Notification.find(notification_id)

    @domain = current_domain
    return unless @notification
    @tip = @notification.notifiable.shareable_object

    mail(
      subject:  "#{@notification.notifier.name} just shared a Card with you",
      to:       @notification.user.email
    )
  end

  def upgrade_subscription_request(user, admin, role)
    @user = user
    @domain = current_domain
    @role = role
    @admin = admin
    mail(subject: 'Friyay request to upgrade role', to: admin.email)
  end

  private

  def host
    return ENV['TIPHIVE_HOST'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}.friyayapp.io"
  end

  def current_domain
    return Domain.new(tenant_name: 'public', join_type: 'open') if Apartment::Tenant.current == 'public'

    Domain.find_by(tenant_name: Apartment::Tenant.current)
  end
end
