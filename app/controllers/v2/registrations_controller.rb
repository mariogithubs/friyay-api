module V2
  class RegistrationsController < ApplicationController
    def create
      # return render_errors('Please verify you are not a robot') unless verify_recaptcha

      @user = User.new(user_params)
      # TODO: Ensure we're only responding to inivitations that are pending
      # Question: how do we handle invitations that are already accepted, but the person
      # doesn't realize it? "it appears you've alreay accepted this invitation. Login?"
      @invitation = Invitation.find_by(invitation_token: params[:invitation_token])

      return render_errors('Error Logged') if spammer_detected?
      # Rails.logger.info("\n\n***** Testing invitation ******\n\n")
      return render_errors('This domain requires an invitation') if invitation_needed? && @invitation.blank?
      # Rails.logger.info("\n\n***** Testing email_allowed: #{email_allowed?} ******\n\n")
      return render_errors('You must have a company email address.') unless email_allowed?

      @user.save
      return render_errors(@user.errors.full_messages) if @user.errors.any?

      join_user_to_domain unless invitation_accepted?

      # Sign in after user is successfully created
      sign_in @user, store: true

      render json: UserAuthenticatedSerializer.new(@user), status: :created, location: [:v2, @user]
    end

    def confirm
      @user = User.confirm_by_token(params[:confirmation_token])
      return render_errors('Incorrect link.') unless @user
      if @user.errors.empty?
        sign_in @user, store: true
        render json: UserAuthenticatedSerializer.new(@user), status: :created, location: [:v2, @user]
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :username)
    end

    def email_allowed?
      return true if @invitation.try(:email) == @user.email
      return true if current_domain.tenant_name == 'public'
      return true if current_domain.open?
      return true if current_domain.email_domains.blank? # Meaning we don't want to limit

      current_domain.email_acceptable?(@user.email)
    end

    def invitation_needed?
      current_domain.invitation_required?
    end

    def invitation_accepted?
      return false if params[:invitation_token].blank?
      return false if @invitation.blank?

      @invitation.connect(@user)
    end

    def spammer_detected?
      spammer_domains = %w(qq.com sina.com)
      spammer_domains.map! { |domain| "@#{domain}" }

      spammer_domains.any? { |domain| @user.email.ends_with?(domain) }
    end

    def join_user_to_domain
      return if current_domain.tenant_name == 'public'
      return unless current_domain.open?

      @user.join(current_domain)
      @user.connect_to_existing_topics
      @user.connect_to_existing_domain_members
    end
  end
end
