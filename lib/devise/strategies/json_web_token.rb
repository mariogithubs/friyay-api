require 'json_web_token'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class JsonWebToken < Authenticatable
      def valid?
        request.headers['Authorization'].present? || request.params['auth_token'].present?
      end

      def authenticate!
        Rails.logger.info "====> JWT authenticate! CLAIMS: #{claims}"
        resource = User.find_by_id(claims.fetch('user_id'))
        if resource
          remember_me resource
          success! resource
        else
          fail!
        end
      end

      private

      def claims
        auth_header = request.headers['Authorization'] || request.params['auth_token']
        token = auth_header.split(' ').last
        auth_header && token && ::JsonWebToken.decode(token)
      rescue
        nil
      end
    end
  end
end

# We already add it in Devise initializer file
# Warden::Strategies.add(:json_web_token, Devise::Strategies::JsonWebToken)
