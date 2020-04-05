module V2
  class SamlController < ApplicationController
    before_action :authorize_domain
    before_action :init_settings

    def relay
      render json: params, status: :ok
    end

    def init
      request = OneLogin::RubySaml::Authrequest.new

      render json: { auth_request: request.create(@settings) }, status: :ok
    end

    def auth
      response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: @settings)

      render_errors(response.errors) && return unless response.is_valid?

      user = User.saml_authenticate(nameid: response.nameid, attributes: response.attributes)

      if user.persisted?
        sign_in user, store: true
        render json: user, serializer: UserAuthenticatedSerializer, status: :created, location: [:v2, user]
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def logout
      msg = 'execute logout'
      if params[:SAMLRequest]
        msg = idp_logout_request
      elsif params[:SAMLResponse]
        msg = process_logout_response
      elsif params[:slo]
        sp_logout_request
      else
        render json: { data: msg }, status: :ok
      end
    end

    def metadata
      meta = OneLogin::RubySaml::Metadata.new
      render xml: meta.generate(@settings, true)
    end

    protected

    def sp_logout_request
      if @settings.idp_slo_target_url.nil?
        # reset_session
        render json: { data: 'SLO IdP Endpoint not found in settings, execute a normal logout' } && return
      else
        # Since we created a new SAML request, save the transaction_id
        # to compare it with the response we get back

        logout_request = OneLogin::RubySaml::Logoutrequest.new

        # session[:transaction_id] = logout_request.uuid

        # logger.info "New SP SLO for User ID: '#{session[:nameid]}', Transaction ID: '#{session[:transaction_id]}'"

        @settings.name_identifier_value = params[:email]

        relay_state = url_for controller: 'v2/saml', action: 'relay'

        render json: {
          transaction_id: logout_request.uuid,
          logout_request: logout_request.create(@settings,
                                                RelayState: relay_state
                                               )
        }, status: :ok
      end
    end

    # After sending an SP initiated LogoutRequest to the IdP, we need to accept
    # the LogoutResponse, verify it, then actually delete our session.
    def process_logout_response
      request_id = params[:transaction_id]

      logout_response = OneLogin::RubySaml::Logoutresponse.new(
        params[:SAMLResponse],
        @settings,
        matches_request_id: request_id,
        get_params: params
      )

      render_errors(
        "The SAML Logout Response is invalid. Errors: #{logout_response.errors}"
      ) && return unless logout_response.validate

      sign_out current_user if logout_response.success?

      render head: :no_content
    end

    # Method to handle IdP initiated logouts
    def idp_logout_request
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], settings: @settings)

      render_errors(
        "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
      ) && return unless logout_request.is_valid?

      logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(
        @settings,
        logout_request.id,
        nil,
        RelayState: params[:RelayState]
      )

      sign_out current_user if logout_response.success?

      # if logout_response.success?
      #   render json: {
      #     data: "execute logout for #{current_user.email}",
      #     logout_response: logout_response
      #   }
      # else
      #   render json: {
      #     data: "failed logout for #{current_user.email}",
      #     logout_response: logout_response
      #   }
      # end

      render head: :no_content
    end

    def url_base
      "#{request.protocol}#{request.host_with_port}"
    end

    private

    def authorize_domain
      return render json: {
        errors: ['SSO feature not enabled for public domain.']
      }, status: :not_found unless current_domain.private_domain?

      return render json: {
        errors: ['SSO feature not enabled for this domain.']
      }, status: :not_found unless current_domain.sso_enabled?
    end

    def init_settings
      @settings = User.get_saml_settings(url_base, current_domain)
      render_errors('No settings available!') && return if @settings.nil?
    end
  end
end
