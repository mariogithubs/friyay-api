module Join
  module Topic
    extend ActiveSupport::Concern

    included do
      after_create :connect
    end

    private

    def connect
      return true if Apartment::Tenant.current == 'public'

      connect_topic_to_resources
    end

    def connect_topic_to_resources
      return true unless is_root?

      connect_existing_domain_members_to_new_hive
    end

    def connect_existing_domain_members_to_new_hive
      # TODO: Test
      UsersFollowingQuery.new(::DomainMember.all).all_topics.each.each do |user|
        ConnectWorker.perform_in(10.seconds, user.id, id, self.class.to_s)
      end
    end
  end
end
