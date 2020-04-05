class InvitationMailer < ApplicationMailer
  add_template_helper(EmailsHelper)

  default from: 'Friyay <Friyay@friyay.io>'

  def account(invitation_id)
    find_invitation invitation_id

    return unless @invitation

    mail(
      subject:  "You are invited to join #{@invitation.title} on Friyay",
      to:       @invitation.email
    )
  end

  def domain(invitation_id)
    find_invitation invitation_id

    return unless @invitation

    @new_domain = @invitation.hosturl

    mail(
      subject:  "You are invited to join the #{@invitation.domain_name} workspace on Friyay",
      to:       @invitation.email
    )
  end

  def guest(invitation_id)
    find_invitation invitation_id

    return unless @invitation

    @new_domain = @invitation.hosturl

    mail(
      subject:  "You are invited to be a guest on the #{@invitation.domain_name} workspace on Friyay",
      to:       @invitation.email
    )
  end

  def share(invitation_id)
    find_invitation invitation_id

    return unless @invitation
    @resource = @invitation.invitable

    mail(
      subject:  share_subject,
      to:       @invitation.email
    )
  end

  # TODO: This is for a future time
  # def group(invitation_id)
  #   find_invitation invitation_id

  #   return unless @invitation

  #   @group = @invitation.invitable

  #   mail(
  #     subject:  "You are invited to join #{@invitation.title} on TipHive",
  #     to:       @invitation.email
  #   )
  # end

  def accept(invitation_id, user_id)
    find_invitation invitation_id

    return unless @invitation

    @user = User.find_by_id user_id

    @domain = current_domain

    return unless @user

    subject = "#{@user.first_name} accepted your invitation"
    subject += " on the #{@domain.name} workspace" unless Apartment::Tenant.current == 'public'
    subject += ' on Friyay'

    mail(
      subject:  subject,
      to:       @invitation.user.email
    )
  end

  def remind(invitation_id)
    find_invitation invitation_id

    return if !@invitation || @invitation.accepted

    mail(
      subject:  'Your invite to Friyay is waiting for you',
      to:       @invitation.email
    )
  end

  def reinvite(invitation_id)
    find_invitation invitation_id

    return unless @invitation

    mail(
      subject:  'Reminder to join me on Friyay',
      to:       @invitation.email
    )
  end

  def requested(invitation_id)
    find_invitation invitation_id

    return unless @invitation

    subject = "Someone has requsted an invitation to the #{@invitation.domain_name} workspace."

    mail(
      subject: subject,
      to: @invitation.user.email
    )
  end

  def reminder(invitation_id, domain)
    @invitation = Invitation.find(invitation_id)
    @domain = domain
    @invite_url = build_invite_url

    return unless @invitation

    mail(
      subject:  "Your invite to #{@domain.tenant_name} workspace on Friyay is waiting for you.",
      to:       @invitation.email
    )
  end

  private

  def find_invitation(invitation_id)
    @domain = current_domain
    @invitation = Invitation.find(invitation_id)
    @invite_url = build_invite_url
  end

  def build_invite_url
    "https://#{@domain.host_url}/join?invitation_token=#{@invitation.invitation_token}&email=#{@invitation.email}"
  end

  def host
    return ENV['TIPHIVE_HOST'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}.friyayapp.io"
  end

  def current_domain
    return Domain.new(tenant_name: 'public', join_type: 'open') if Apartment::Tenant.current == 'public'

    Domain.find_by(tenant_name: Apartment::Tenant.current)
  end

  def share_subject
    return I18n.t(
      'notifications.invitations.share_public.subject',
      title: @resource.title,
      user: @invitation.user.name
    ) if @domain.public_domain?

    I18n.t(
      'notifications.invitations.share_private.subject',
      domain: @domain.name,
      title: @resource.title,
      user: @invitation.user.name
    )
  end
end
