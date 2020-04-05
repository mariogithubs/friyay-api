module Join
  module UserProfile
    extend ActiveSupport::Concern

    included do
      after_save :observe_follow_flags
    end

    private

    def observe_follow_flags
      return true if current_domain.public_domain?

      follow_existing_topics
      follow_existing_domain_members
    end

    def follow_existing_topics
      return true unless follow_all_topics

      user.connect_to_existing_topics
    end

    def follow_existing_domain_members
      return true unless follow_all_domain_members

      user.connect_to_existing_domain_members
    end
  end
end
