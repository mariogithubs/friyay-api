module V2
  class InvitationsController < ApplicationController
    before_action :authenticate_user!, except: [:request_invitation]

    def index
      invitations = current_user.invitations
      invitations = invitations.pending if params[:status] == 'pending'
      invitations = invitations.requested if params[:status] == 'requested'

      render json: invitations
    end

    def show
      invitation = current_user.invitations.find_by_id(params[:id])

      render json: invitation, status: :created, location: [:v2, invitation]
    end

    def search
      Invitation.search_emails(params[:emails]) if params[:emails].present?
    end

    def create
      return render_errors('No emails found') unless invitation_params[:emails]
      allowed_emails = exclude_disallowed_emails(invitation_params[:emails])
      return render json: {}, status: :created unless allowed_emails.present?
      #status is created because it is silently blocked

      # TODO: I think we need to check for invitable presence

      invitations = []

      type_data = ensure_correct_invitation_type

      invalid_email_errors = validate_emails(allowed_emails)

      return render_errors(invalid_email_errors) if invalid_email_errors.present?

      allowed_emails.each do |email|
        invitation = Invitation.where(
          'invitable_type = ? and invitable_id = ?  and email ILIKE ?',
          type_data[:invitable_type],
          type_data[:invitable_id],
          email
        ).first

        invitation.resend! if invitation

        invitation ||= current_user.invitations.create(invitation_data(email, type_data))

        invitations << invitation
      end

      render json: invitations, status: :created
    end

    def reinvite
      invitation = current_user.invitations.find_by_id(params[:id])

      return render_errors('No invitation found') unless invitation

      invitation.reinvite

      render json: invitation, status: :created, location: [:v2, invitation]
    end

    def request_invitation
      invitation_data = {
        attributes: {
          user_id: invitation_user.id,
          email: invitation_params[:email],
          first_name: invitation_params[:first_name],
          last_name: invitation_params[:last_name],
          invitation_type: 'domain',
          invitable_type: 'Domain',
          invitable_id: current_domain.id,
          state: 'requested',
          custom_message: "#{build_name} has requested an invitation."
        }
      }

      invitation = Invitation.create(invitation_data)
      # notify inviter that someone has requested an invitation

      render json: invitation, status: :created
    end

    private

    def invitation_params
      params.require(:data)
        .permit(
          :invitation_type,
          :invitable_type,
          :invitable_id,
          :custom_message,
          :first_name,
          :last_name,
          :email,
          emails: [],
          options: { topics: [:id, tips: []], groups: [], users: [] }
        )
    end

    def invitation_not_intended(email)
      email != current_user.email
    end

    def invitation_user
      current_user || current_domain.user
    end

    def build_name
      name = [invitation_params[:first_name], invitation_params[:last_name]].compact.join(' ')
      name.blank? ? 'No Name' : name
    end

    def ensure_correct_invitation_type
      # TODO: This logic could probably move to the model or library
      return invitation_params if current_domain.tenant_name == 'public'
      return invitation_params if invitation_params[:invitation_type] == 'share'
      return guest_invitation_params if invitation_params[:invitation_type] == 'guest'

      # admin
      # guest
      # The default invitation type
      { invitation_type: 'domain', invitable_type: 'Domain', invitable_id: current_domain.id }
    end

    def guest_invitation_params
      # TODO: This needs refactoring, shouldn't be rewriting things sent from front end
      { invitation_type: 'guest', invitable_type: 'Domain', invitable_id: current_domain.id }
    end

    def invitation_data(email, type_data)
      {
        attributes: {
          email: email,
          invitation_type: type_data[:invitation_type],
          invitable_type: type_data[:invitable_type],
          invitable_id: type_data[:invitable_id],
          custom_message: invitation_params[:custom_message],
          options: invitation_params[:options] || {}
        }
      }
    end

    def validate_emails(emails)
      # don't allow sending more than 10 invitations at a time to prevent spamming
      return 'You may only send up to 10 invitations at a time' if emails.count > 10

      invalid_emails = []
      emails.each do |email|
        invalid_emails << email unless email.match(Devise.email_regexp)
      end

      return false if invalid_emails.blank?
      I18n.t('errors.invitations.invalid_emails_html', invalid_emails: invalid_emails.join(', '))
    end

    def exclude_disallowed_emails(emails)
      disallowed_domains = ['qq.com']
      emails.delete_if { |email| disallowed_domains.any?{|domain| email.ends_with?(domain)} }
      return  emails 
    end  
  end
end
