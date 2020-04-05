class JsonWebToken
  class << self
    # Teefan: I don't think any expiration number larger than 2 weeks is a good idea.
    # Please consult with the team before making any change.
    def encode(payload, exp = (24 * 14).hours.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, Rails.application.secrets.secret_key_base)
    end

    def decode(token)
      body = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
      HashWithIndifferentAccess.new body
    rescue JWT::DecodeError => e
      error_message = e.message

      Rails.logger.error "===> EXCEPTION OCCURRED: #{error_message}"
      e.backtrace.each do |line|
        Rails.logger.error "===> #{line}"
      end

      error_message
    end
  end
end
