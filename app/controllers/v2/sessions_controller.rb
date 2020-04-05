module V2
  class SessionsController < ApplicationController
    before_action :authenticate_user!, only: [:destroy]

    def create
      if params[:user].blank?
        render(json: { errors: ['Missing user parameter.'] }, status: :unprocessable_entity) && return
      end

      @user = User.find_for_database_authentication(email: params[:user][:email])

      render_errors('Invalid email or password.') && return if not_a_valid_login?

      # Tell warden that params authentication is allowed
      allow_params_authentication!
      @user = warden.authenticate!(scope: :user)

      sign_in @user, store: true
      render json: UserAuthenticatedSerializer.new(@user, { params: { domain: current_domain } }), status: :ok, location: [:v2, @user]
    end

    def destroy
      sign_out current_user
      head :no_content
    end

    def not_a_valid_login?
      return true if @user.blank?
      return true if @user.valid_password?(params[:user][:password]) == false
      return false if current_domain.tenant_name == 'public'
      return true unless @user.member_or_power_or_guest_of?(current_domain)

      false
    end
  end
end
