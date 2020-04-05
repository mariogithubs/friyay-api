class InvitationActivityNotificationMailer < ApplicationMailer
  add_template_helper(EmailsHelper)

  default from: "Friyay <#{ENV['TIPHIVE_EMAIL_ADMIN']}>"

  def someone_adds_topic(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain

    return unless @notification

    @topic = @notification.notifiable

    mail(
      subject: "#{@notification.notifier.name} just added a topic to #{@domain.tenant_name}",
      to:      @notification.user.email
    )
  end

  def someone_joins_domain(notification_id, _opts = {})
    @notification = Notification.find(notification_id)
    @domain = current_domain

    return unless @notification

    @new_domain = @notification.notifiable.domain

    mail(
      subject: "#{@notification.notifier.name} just joined the #{@new_domain.name} workspace",
      to:      @notification.user.email
    )
  end

  def daily_feed_email(params, _opts = {})
    email            = params['email']
    notification_ids = params['notification_ids']
    invitation_id    = params['invitation_id']

    @domain = current_domain
    @host_options = { host: @domain.host_url, protocol: 'https' }

    @notifications = Notification.where('id in (?)', notification_ids)
    @invitation    = Invitation.find_by_id invitation_id
    @invite_url    = "https://#{@domain.host_url}/join?invitation_token=#{@invitation.invitation_token}"

    mail(subject: "Daily Summary for #{@domain.name} workspace", to: email)
  end

  def tip_feed(params, _opts = {})
    email            = params['email']
    notification_ids = params['notification_ids']
    @domain = current_domain
    @notifications = Notification.where('id in (?)', notification_ids)

    mail(subject: 'Friyay Summary', to: email)
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
