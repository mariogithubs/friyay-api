require "#{Rails.root}/lib/extensions/time_extensions.rb"

module ActiveRecord
  class Base
    def current_domain
      Domain.find_by(tenant_name: Apartment::Tenant.current) ||
        Domain.new(tenant_name: 'public', join_type: 'open')
    end
  end
end
