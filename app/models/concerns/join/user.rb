module Join
  module User
    extend ActiveSupport::Concern

    def connect_with(resource)
      if resource.is_a?(User)
        follow! resource
      else
        follow resource
      end
    end

    def connect_to_existing_topics
      ignore_topic_ids = following_topics.ids

      ::Topic.without_root.where.not(id: ignore_topic_ids).each do |hive|
        ConnectWorker.perform_in(10.seconds, id, hive.id, hive.class.to_s)
      end
    end

    def connect_to_existing_domain_members
      ignore_user_ids = following_users.ids + [id]

      ::DomainMember.where.not(id: ignore_user_ids).find_each do |domain_member|
        if Rails.env == 'test'
          follow(domain_member)
        else
          ConnectWorker.perform_in(10.seconds, id, domain_member.id, self.class.to_s)
        end
      end

      connect_existing_to_new_user(ignore_user_ids) unless Rails.env == 'test'
    end

    private

    def connect_existing_to_new_user(ignore_ids)
      UsersFollowingQuery.new(::DomainMember.where.not(id: ignore_ids)).all_domain_members.each do |domain_member|
        ConnectWorker.perform_in(10.seconds, domain_member.id, id, self.class.to_s)
      end
    end
  end
end
