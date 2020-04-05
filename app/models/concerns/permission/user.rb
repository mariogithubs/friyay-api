module Permission
  module User
    extend ActiveSupport::Concern

    included do
      attr_accessor :current_topic

      delegate :can?, :cannot?, to: :ability
    end

    def ability
      @ability ||= Ability.new(self, current_domain, current_topic)
    end
  end
end
