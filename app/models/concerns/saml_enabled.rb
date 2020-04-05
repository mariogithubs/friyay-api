module SamlEnabled
  extend ActiveSupport::Concern

  class_methods do
    def get_saml_settings(url_base, domain)
      settings = OneLogin::RubySaml::Settings.new

      settings.idp_entity_id      = domain.idp_entity_id
      settings.idp_sso_target_url = domain.idp_sso_target_url
      settings.idp_slo_target_url = domain.idp_slo_target_url
      settings.idp_cert = File.read "#{Rails.root}/vendor/certs/#{domain.tenant_name}.cer"

      settings.name_identifier_format = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
      settings.authn_context = 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'
      settings.soft = true
      settings.security[:authn_requests_signed] = false
      settings.security[:logout_requests_signed] = false
      settings.security[:logout_responses_signed] = false
      settings.security[:metadata_signed] = false
      settings.security[:digest_method] = XMLSecurity::Document::SHA1
      settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1
      settings.issuer                         = domain.issuer
      settings.assertion_consumer_service_url = url_base + '/v2/saml/auth'
      settings.assertion_consumer_logout_service_url = url_base + '/v2/saml/logout'

      settings
    end

    def connect_to_domain(connectable_user)
      domain = Domain.find_by_tenant_name(Apartment::Tenant.current)
      return unless domain
      connectable_user.join(domain)
    end

    def saml_authenticate(params)
      attrs = Hash[params[:attributes].attributes]

      email = attrs['email'][0]
      # username = params[:nameid]

      user = User.find_or_initialize_by(email: email) do |u|
        pass = [('a'..'z'), ('A'..'Z'), [email], (0..9)].map(&:to_a).flatten
        pass = (0...20).map { pass[rand(pass.length)] }.join

        u.password = pass
        u.password_confirmation = pass

        u.first_name = attrs['first_name'][0]
        u.last_name = attrs['last_name'][0]

        if u.save
          NotificationWorker.perform_in(1.second, 'sso_welcome', u.id, u.class.to_s)
          connect_to_domain(u)
        end

        u
      end

      user
    end
  end
end
