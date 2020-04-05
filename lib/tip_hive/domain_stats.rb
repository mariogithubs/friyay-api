module TipHive
  # rubocop:disable Rails/Output
  class DomainStats
    attr_accessor :domain

    def initialize(domain = nil)
      @domain = domain_or_current(domain)
    end

    TH_MODELS = %w(
      Topic
      TopicPreference
      Tip
      Question
      Group
      Follow
      Attachment
      Comment
      Flag
      Invitation
      List
      Notification
      ShareSetting
      Role
      TipLink
      TopicUser
    )

    def counts
      Apartment::Tenant.switch @domain.tenant_name do
        stats = []
        TH_MODELS.each do |model|
          model_sym = [model.camelize, 'count'].join('_').to_sym
          stats << { resource: model_sym,
                     value: model.constantize.select(:id).count
          }
        end

        stats.prepend(resource: 'DomainMember_count', value: @domain.members.count)

        puts "\n**** Counts for Domain: #{@domain.name} ****"

        puts Hirb::Helpers::AutoTable.render(
          stats,
          fields: [:resource, :value],
          headers: {
            resource: 'Resource',
            value:    'Value'
          }
        )
      end # Apartment
    end # Counts

    private

    def domain_or_current(domain)
      return Domain.find_by(tenant_name: Apartment::Tenant.current) unless domain
      Domain.find_by(tenant_name: domain)
    end
  end # DomainStats
  # rubocop:enable Rails/Output
end
