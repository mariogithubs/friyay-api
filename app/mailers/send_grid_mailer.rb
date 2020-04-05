class SendGridMailer
  # NOTE: THIS IS NOT A STANDARD RAILS MAILER
  # IT SENDS MAIL USING THE SENDGRID GEM
  include SendGrid

  attr_accessor :action

  def initialize(action, params, options = {})
    @from = Email.new(email: ENV['TIPHIVE_EMAIL_ADMIN'], name: 'Friyay')

    @personalization = send(action, params.is_a?(Hash) ? params : params.to_s, options)
  end

  def someone_mentioned_on_comment(notification_id, _opts = {})
    @template_id = '4e417623-9596-43ee-9b4c-a699656ded56'
    notification = Notification.find(notification_id.to_i)

    return unless notification

    notifier_name = notification.notifier.name
    @to_user = notification.user

    tip = notification.notifiable.commentable
    comment_body = notification.notifiable.body

    tip_url = "https://#{host}/cards/#{tip.slug}"

    @personalization = Personalization.new
    build_common_substitutions

    @personalization.to = Email.new(email: @to_user.email, name: @to_user.name)
    @personalization.substitutions = Substitution.new(key: ':first_name', value: @to_user.first_name)
    @personalization.substitutions = Substitution.new(key: ':notifier_name', value: notifier_name)
    @personalization.substitutions = Substitution.new(key: ':tip_title', value: tip.title)
    @personalization.substitutions = Substitution.new(key: ':tip_url', value: tip_url)
    @personalization.substitutions = Substitution.new(key: ':comment_body', value: comment_body)

    @personalization
  end

  # def someone_comments_on_tip(notification_id, _opts = {})
  #   @template_id = '96098780-1b52-4334-bc10-370df2103027'
  #   notification = Notification.find(notification_id)

  #   tip_title = notification.notifiable.commentable.title
  #   comment_body = notification.notifiable.body
  #   notifier_name = notification.notifier.name

  #   return unless notification

  #   @personalization = Personalization.new
  #   @personalization.to = Email.new(email: notification.user.email, name: notification.user.name)
  #   @personalization.substitutions = Substitution.new(key: ':first_name', value: notification.user.first_name)
  #   @personalization.substitutions = Substitution.new(key: ':domain_name', value: current_domain.name)
  #   @personalization.substitutions = Substitution.new(key: ':tip_title', value: tip_title)
  #   @personalization.substitutions = Substitution.new(key: ':comment_body', value: comment_body)
  #   @personalization.substitutions = Substitution.new(key: ':notifier_name', value: notifier_name)
  # end

  # def join_a_domain(notification_id, _opts = {})
  #   @template_id = '38e11411-2a8a-47ce-a9eb-5f3a4ff7c22d'
  #   notification = Notification.find(notification_id.to_i)

  #   return unless notification
  #   new_domain = notification.notifiable.domain

  #   @personalization = Personalization.new
  #   @personalization.to = notification.user.email
  #   @personalization.substitutions = Substitution.new(key: ':first_name', value: notification.user.first_name)
  #   @personalization.substitutions = Substitution.new(key: ':domain_name', value: new_domain.name)
  # end

  # def someone_joins_domain(notification_id, opts = {})
  #   @template_id = '0e7fd733-3c6b-432d-b77b-7251407b0675' if opts[:role] = 'guest'
  #   @template_id = @template_id || '38e11411-2a8a-47ce-a9eb-5f3a4ff7c22d'
  #   notification = Notification.find(notification_id.to_i)

  #   return unless notification
  #   new_domain = notification.notifiable.domain

  #   @personalization = Personalization.new
  #   @personalization.to = notification.user.email
  #   @personalization.substitutions = Substitution.new(key: ':first_name', value: notification.user.first_name)
  #   @personalization.substitutions = Substitution.new(key: ':domain_name', value: new_domain.name)
  # end

  def deliver
    mail = SendGrid::Mail.new
    mail.from = @from
    mail.personalizations = @personalization
    mail.template_id = @template_id

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])

    mock_send(mail.to_json) && return if Rails.env == 'development'

    begin
      sg.client.mail._('send').post(request_body: mail.to_json)
    rescue StandardError => e
      Rails.logger.info("\n\n***** #{e.message} ******\n\n")
    end
  end

  private

  def build_common_substitutions(options = {})
    standard_subs = {
      domain_name: current_domain.name,
      notification_settings: "https://#{ENV['TIPHIVE_HOST']}?pop=setting"
    }

    remove_keys = options.select { |_, value| value == false }.keys

    substitutions = standard_subs.reject { |key, _| remove_keys.include?(key) }

    substitutions.each do |key, value|
      send_grid_key = [':', key].join
      @personalization.substitutions = Substitution.new(key: send_grid_key, value: value)
    end

    @personalization
  end

  def host
    return ENV['TIPHIVE_HOST'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}.friyayapp.io"
  end

  def current_domain
    return Domain.new(tenant_name: 'public', join_type: 'open') if Apartment::Tenant.current == 'public'

    Domain.find_by(tenant_name: Apartment::Tenant.current)
  end

  def mock_send(mail_data)
    Rails.logger.info("\n\n***** eMailing: #{mail_data} ******\n\n")
  end
end
