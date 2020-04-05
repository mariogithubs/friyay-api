module TaskHelpers
  def self.connection
    @connection ||= ActiveRecord::Base.connection
  end

  def self.gather_domain_names(specific_tenant_name = nil)
    # Returns [tenant_names], not [domain_names]
    domains = []

    domains << Domain.find_by(tenant_name: specific_tenant_name) if specific_tenant_name
    return domains.map(&:tenant_name).sort if specific_tenant_name

    domains = Domain.all
    domains << Domain.new(tenant_name: 'public')

    domains.map(&:tenant_name).sort
  end
end
