class AdminMailer < ApplicationMailer
  add_template_helper(EmailsHelper)

  default from: "Friyay <#{ENV['TIPHIVE_EMAIL_ADMIN']}>"

  def flag(flag_id)
    @flag = Flag.find_by(id: flag_id)
    return if @flag.blank?

    @flagger = @flag.flagger
    mail(
      subject:  "A #{@flag.flaggable_type} has been flagged.",
      to:       'madiken@friyay.io'
    )
  end

  def domain_created(domain)
    @domain = domain
    return if @domain.blank?

    @user = @domain.user
    @host = "#{@domain.tenant_name}.friyayapp.io"

    mail(
      subject: "New Workspace Notice: #{@domain.name} has been created",
      to:      'madiken@friyay.io'
    )
  end

  def notify(opts)
    @body = opts[:body]

    mail(
      subject: opts[:subject] || 'Admin notification',
      to: 'anthony@friyay.io'
    )
  end

  def process_finished(process, attachment_name = nil, attachment_path = nil)
    attachments[attachment_name] = File.read(attachment_path) if attachment_name && attachment_path

    mail(
      subject: "Process Finished: #{process} should have finished",
      to:      'anthony@friyay.io'
    )
  end

  def new_domain_members(domain_csv, users_csv)
    domain_attachment = "domain_users_#{Time.zone.now.strftime('%m_%d_%y')}.csv"
    users_attachment = "users_#{Time.zone.now.strftime('%m_%d_%y')}.csv"

    attachments[domain_attachment] = { mime_type: 'text/csv', content: domain_csv }
    attachments[users_attachment] = { mime_type: 'text/csv', content: users_csv }

    mail(subject: 'New Workspace Members', to: 'madiken@friyay.io, shannice@friyay.io')
  end

  private

  def host
    return ENV['TIPHIVE_HOST'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}.friyayapp.io"
  end
end
