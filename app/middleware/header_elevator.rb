require 'apartment/elevators/generic'

module Apartment
  module Elevators
    class HeaderElevator < Generic
      # @return {String} - The tenant to switch to
      def parse_tenant_name(request)
        # Rails.logger.info("\n ****** #{request.inspect} ****** \n")

        tenant_name = request.env['HTTP_X_TENANT_NAME']
        tenant_name = parse_subdomain(request) if tenant_name.blank?

        return tenant_name if Apartment.tenant_names.include?(tenant_name)

        'public'
      end

      def parse_subdomain(request)
        return request.env['HTTP_HOST'].split('.').reverse[2] unless request.env.key?('HTTP_ORIGIN')

        host = URI.parse(request.env['HTTP_ORIGIN']).host

        # ActionDispatch::Http::URL.extract_subdomain(host, 1) # tld_length =

        # Don't try to extract, just get the first part of the host
        host.split('.').first
      end
    end
  end
end
