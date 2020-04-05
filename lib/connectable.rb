# TODO: move share methods into shareable and include shareable into this
# CAUTION: Ensure that models are not includeing both connectable AND shareable if we do that
# rubocop:disable Metrics/ModuleLength
module Connectable
  OVERRIDE_TYPES = %w(everyone following private link linkWithPassword linkWithAccess)
  FOLLOWER_TYPES = %w(users groups lists)

  module Model
    extend ActiveSupport::Concern
    include SlackActions
    attr_accessor :current_user

    def follow_multiple_resources(type, json_objects, current_user = nil, params = nil)
      return if json_objects.with_indifferent_access['data'].blank?

      resources_to_follow = resource_list(type, json_objects, current_user, params)
      currently_following_resources = following_list(type)

      resources_to_drop = currently_following_resources - resources_to_follow

      resources_to_follow = reject_restricting_resources(resources_to_follow, current_user)

      resources_to_follow.each do |resource|
        follow(resource)
        follow_ancestry(resource) unless type == :topic
      end

      resources_to_drop.each do |resource|
        stop_following(resource)
      end
    end

    def reject_restricting_resources(all_resources, current_user)
      return all_resources unless current_user
      return all_resources if self.is_a?(Group)

      reject_arr = all_resources.collect { |rtf| rtf.id if rtf.is_a?(Topic) && !rtf.can_create?(self, current_user) }

      reject_arr.compact!

      return all_resources if reject_arr.empty?

      all_resources = all_resources.where('id not in (?)', reject_arr)

      all_resources
    end

    def follow_tip(parent_tip)
      return if parent_tip.blank?
      return unless parent_tip.key?(:data)
      return if parent_tip[:data].blank?

      parent_tip = Tip.find_by(id: parent_tip[:data].try(:[], :id))
      return if following_tips.include?(parent_tip)

      follow(parent_tip)
    end

    # *************************************************
    # TODO: refactor these share_with to be better OO methods
    # This was quickly created to reduce line length in controllers
    # *************************************************

    def share_with_all_relationships(params, current_user = nil)
      params = params.with_indifferent_access
      self.current_user = current_user if current_user
      create_user_followers_from_parent

      if private_override?(params)
        make_private
        return
      end

      invite_relationships(user_invitations_list(params))
      sharing_list = get_list(params, 'share_settings')
      follower_list = get_list(params, 'user_followers')

      if sharing_list.blank? and self.is_a?(Tip) and params[:action] == 'create'
        follower_list = tip_take_settings_of_topic(params)
      else
        share_with_relationships('users', sharing_list)
        share_with_relationships('groups', sharing_list)
      end
      connect_followers(follower_list)
    end

    def connect_followers(follower_list)
      return if follower_list.blank? || follower_list.try(:[], :data).blank?
      follower_list[:data].collect do |follower|
        if follower['type'] == 'users' and !OVERRIDE_TYPES.include? follower['id']
          User.find(follower['id']).follow(self)
        end
      end
    end

    def get_list(params, relation)
      # TODO: refactor so this returns actual list of users
      # Returns { data: [{id: id, type: 'users'}...] }
      list = params['data'].try(:[], 'relationships').try(:[], relation)
      #group_list = params['data'].try(:[], 'relationships').try(:[], 'group_followers')
      Rails.logger.info("\n\n** rlog ====> list.blank? #{list.blank?} ******\n\n")

      return [] if list.try(:[], 'data').blank?

      users_list = list.try(:[], 'data').blank? ? [] : list['data'].select { |k| k['type'] == 'users' }
      groups_list = list.try(:[], 'data').blank? ? [] : list['data'].select { |k| k['type'] == 'groups' }

      share_with_overrides(params)

      { data: users_list + groups_list - extract_overrides(params) }
    end

    def tip_take_settings_of_topic(params)
      topic = params['data'].try(:[], 'relationships').try(:[], 'subtopics').try(:[], 'data')
      return [] unless topic.present?

      topic = Topic.find_by(id: topic.first.try(:[], 'id'))

      topic_preference = topic.topic_preferences.for_user(current_user)
      return [] unless topic_preference.present?

      self.share_public = topic_preference.share_public?
      self.share_following = topic_preference.share_following?

      save
      
      topic_users = topic.share_settings.where(:sharing_object_type => ['User']).pluck(:sharing_object_id)
      topic_groups = topic.share_settings.where(:sharing_object_type => ['Group']).pluck(:sharing_object_id)
      return [] unless topic_users.present? or topic_groups.present?
      user_list = []
      group_list = []

      topic_users.each do |object_id|
        user_list << {id: object_id.to_s, type: 'users'}

      end
      topic_groups.each do |object_id|
        group_list << {id: object_id.to_s, type: 'groups'}
      end
      
      share_with_relationships('users', { data: user_list })
      share_with_relationships('groups', { data: group_list })

      { data: user_list.concat(group_list) }
    end  

    def user_invitations_list(params)
      list = params['data'].try(:[], 'relationships').try(:[], 'share_settings')
      return [] if list.try(:[], 'data').blank?

      emails_list = list['data'].select { |k| k['type'] == 'emails' } # select existing users list

      emails_list
    end

    def create_user_followers_from_parent(resource = self)
      return unless resource.is_a?(Topic)
      return unless resource.subtopic?

      user_ids = resource.parent.user_followers.pluck(:id)

      already_follower_ids = Follow.where(
        followable: resource,
        follower_type: 'User',
        follower_id: user_ids
      ).pluck(:follower_id)

      non_follower_ids = user_ids - already_follower_ids

      non_follower_ids.each do |user_id|
        ConnectWorker.perform_in(5.seconds, user_id, id, 'Topic')
      end
    end

    def share_with_relationships(relationship_type, json_objects)
      prune_relationships(relationship_type, []) if json_objects.blank? || json_objects.try(:[], :data).blank?
      return if json_objects.blank? || json_objects.try(:[], :data).blank?

      relationships_to_share_with = resource_list(relationship_type, json_objects)
      share_with_user_resources(relationships_to_share_with)

      prune_relationships(relationship_type, relationships_to_share_with)
    end

    def share_with_user_resources(relationships_to_share_with)
      relationships_to_share_with.each do |user_resource|
        share_with_singular_user_resource(user_resource)
      end
    end

    def share_with_singular_user_resource(user_resource)
      find_or_create_share_settings_for(user_resource) unless self.is_a?(Group)

      # TODO: This may not be needed anymore since we are showing
      # tips from descendants anyway
      share_root_with(user_resource) && return if self.is_a?(Topic)

      user_resource.follow(self)
      follow_tips(user_resource) unless user_resource.is_a?(Group)

      relationship_follow_topic(self, user_resource) if self.is_a?(Tip)
    end

    def relationship_follow_topic(resource, relationship)
      # TODO: this will attach all topics a tip follows to the user being shared with
      # Do we want the user to follow all topics?
      resource.following_topics.each do |topic|
        relationship_follow_parent(topic, relationship)
      end
    end

    def relationship_follow_parent(topic, relationship)
      relationship.follow(topic)
      relationship_follow_parent(topic.parent, relationship) if topic.parent
    end

    # ******************* END OF TODO *****************************8

    def connect_attachments(params)
      json_attachments = params['data'].try(:[], 'relationships').try(:[], 'attachments')
      return if json_attachments.blank?

      attachment_list = resource_list('attachment', json_attachments)

      attachment_list.each do |attachment|
        attachment.attachable = self
        attachment.save
      end
    end

    def connect_labels(params)
      json_labels = params['data'].try(:[], 'relationships').try(:[], 'labels')
      if json_labels.try(:[], 'data').blank?
        self.labels = []
        return
      end  
      label_list = resource_list('label', json_labels)

      self.labels = label_list
    end

    def connect_dependency(params)
      depends_on = tip_depends_on(params)
      depended_on_by = tip_depended_on_by(params)

      self.depends_on = depends_on
      self.depended_on_by = depended_on_by
    end

    def connect_tip_assignments(params)
      assigned_users = tip_assigned_users(params)
      assigned_groups = tip_assigned_groups(params)

      # depended_on_by = resource_list('tip_assignments', json_depended_on_by)

      self.assigned_users = assigned_users
      self.assigned_groups = assigned_groups     
    end

    def tip_assigned_users(params)
      json_tip_assignments = params['data'].try(:[], 'relationships').try(:[], 'tip_assignments')

      return [] if json_tip_assignments.try(:[], 'data').blank?  
      tip_assignments = json_tip_assignments.try(:[], 'data')

      assigned_users = tip_assignments.select { |obj| obj[:assignment_type] == "User" }
      resource_list = User.where(id: assigned_users.map { |resource| resource[:assignment_id] })

      resource_list

    end

    def tip_assigned_groups(params)
      json_tip_assignments = params['data'].try(:[], 'relationships').try(:[], 'tip_assignments')

      return [] if json_tip_assignments.try(:[], 'data').blank?  
      tip_assignments = json_tip_assignments.try(:[], 'data')

      assigned_groups = tip_assignments.select { |obj| obj[:assignment_type] == "Group" }
      resource_list = Group.where(id: assigned_groups.map { |resource| resource[:assignment_id] })

      resource_list
    end  

    def tip_depends_on(params)
      json_depends_on = params['data'].try(:[], 'relationships').try(:[], 'depends_on')

      return [] if json_depends_on.try(:[], 'data').blank?  

      depends_on = resource_list('tip', json_depends_on)

      return depends_on
    end

     def tip_depended_on_by(params)
      json_depended_on_by = params['data'].try(:[], 'relationships').try(:[], 'depended_on_by')

      return [] if json_depended_on_by.try(:[], 'data').blank?  

      depended_on_by = resource_list('tip', json_depended_on_by)

      return depended_on_by
    end  

    def viewable_tips_by(user)
      user.viewable_tips(filter_resource: self)
    end

    # def follow_all_topics_followed_by(user)
    # end

    def follow_tips_from_users(topic, users)
      return if users.blank?
      return if guest_of?(current_domain)

      users.each do |user|
        follow_tips_from_user(topic, user)
      end
    end

    def follow_tips_from_user(topic, user)
      topic_preference = topic.topic_preferences.for_user(user)
      follow(topic_preference)
    end

    def follow_tips(user)
      return if user.guest_of?(current_domain)

      tip_followers.each do |tip|
        user.follow(tip)
      end
    end

    class_methods do
      def followed_by(user_or_email)
        user = user_or_email.is_a?(User) ? user_or_email : User.find_by(email: user_or_email)
        joins(:followings).where(follows: { follower_type: 'User', follower_id: user.id })
      end
    end

    def connect_to_resource(resource)
      user.follow(resource)
      resource.follow(user)
    end

    def connect_to_existing_topics
      Topic.select(:id).find_in_batches do |topics|
        following_topics.select(:id).find_in_batches do |following_topics|
          topics -= following_topics
        end

        sql_connect_to_resources('Topic', topics.map(&:id))
      end
    end

    def connect_to_existing_users
      domain = Domain.find_by(tenant_name: Apartment::Tenant.current)

      domain.members.select(:id).find_in_batches do |users|
        following_users.select(:id).find_in_batches do |following_users|
          users -= following_users
        end

        sql_connect_to_resources('User', users.map(&:id))
      end
    end

    def sql_connect_to_resources(resource_type, resource_ids_to_follow)
      data_topics = []
      resource_ids_to_follow.each do |topic_id|
        data_topics << "(#{resource_type}, #{topic_id}, #{self.class}, #{id})"
      end

      return false if data_topics.blank?

      sql =  'INSERT INTO follows (followable_type, followable_id, follower_type, follower_id)'
      sql += " VALUES #{data_topics.join(', ')};"

      begin
        Follow.connection.execute sql
      rescue => e
        Rails.logger.info("\n\n***** Something Failed: #{e} ******\n\n")
      end
    end

    def update_overrides(settings)
      return unless self.respond_to?(:share_public)

      self.share_public = settings[:public]
      self.share_following = settings[:following]
      self.is_secret = settings[:is_secret] if self.is_a?(Tip)

      self.link_option = settings[:link_option] if self.is_a?(TopicPreference)
      self.link_password = settings[:link_password] if self.is_a?(TopicPreference)
      save
    end

    # Sets a resource to be private (tips and topics differ)
    # A private tip will remove all other followers
    # A private topic will make subtopic descendants and tip_followers all private
    def make_private
      resource = resource_to_share_with

      settings = { public: false, following: false }
      resource.update_overrides(settings)

      disconnect_all_user_followers unless self.is_a?(Topic) # Not for topics

      recursively_make_private if self.is_a?(Topic)
    end

    def domain_host
      return ENV['TIPHIVE_HOST_NAME'] if Apartment::Tenant.current == 'public'

      "#{Apartment::Tenant.current}.#{ENV['TIPHIVE_HOST_NAME']}"
    end

    def post_to_slack_channel(tip, topic, text)
      slack_options = {
        response_type: "in_channel",
        text: text,
        channel: self.slack_channel.slack_channel_id,
        token: self.slack_team.access_token,
        attachments: [
          {
            title: tip.title,
            title_link: "https://#{domain_host}/cards/#{tip.slug}",
            fallback: tip.title + " - https://#{domain_host}/cards/#{tip.slug}",
          }
        ].to_json
      }
      begin
        post_message slack_options
      rescue => e
        true
      end    
    end

    private

    def share_with_creator
      followings.create(follower_type: 'User', follower_id: user_id)
    end

    def share_topic_with_creator
      return unless root? || following_parent?
      share_with_creator
    end

    def following_parent?
      Follow.where(
        followable: parent,
        follower_type: 'User',
        follower_id: user_id
      ).any?
    end

    def resource_to_share_with(resource = self)
      # Currently this only works for topics or resources where share_public
      # is on its own class like tip and question
      return resource.topic_preferences.for_user(current_user) if resource.is_a?(Topic)
      # return params[:current_topic_preference] if params.key?(:current_topic_preference)
      resource
    end

    def share_with_overrides(params)
      list = extract_overrides(params)
      resource = resource_to_share_with
      settings = { public: false, following: false, link_option: nil, link_password: nil }

      settings[:public] = true if list.count { |users| users['id'] == 'everyone' } > 0
      settings[:following] = true if list.count { |users| users['id'] == 'following' } > 0
      settings[:is_secret] = self.is_secret if self.is_a?(Topic)
      
      list.count { |users|  
        settings[:link_option] = users[:id] if  users[:type] == "link"
        settings[:link_password] = users[:password]  unless users[:password].nil?
      }
      

      resource.update_overrides(settings)

      recursively_update_overrides(settings, params) if self.is_a?(Topic) && self.apply_to_all_childrens
    end

    def recursively_update_overrides(settings, params)
      update_resource_followers(self, settings, params)

      descendants.each do |subtopic|
        subtopic.update(is_secret: self.is_secret, apply_to_all_childrens: self.apply_to_all_childrens)
        subtopic.share_with_all_relationships(params, current_user)
        resource = resource_to_share_with(subtopic)
        resource.update_overrides(settings)

        # NOTE: This is using subtopic not resource b/c the followers
        # follow the subtopic, not the subtopic_preferences
        update_resource_followers(subtopic, settings, params)
      end
    end

    def private_override?(params)
      list = params['data'].try(:[], 'relationships').try(:[], 'share_settings').try(:[], 'data')
      return if list.blank?
      list.count { |users| users['id'] == 'private' } > 0
    end

    def recursively_make_private
      make_resource_followers_private(self)

      children.each do |subtopic|
        resource = resource_to_share_with(subtopic)
        resource.make_private

        make_resource_followers_private(subtopic)
      end
    end

    def make_resource_followers_private(topic)
      # This only applies to Tips and Questions
      topic.tip_followers.where(user_id: current_user.id).each do |tip|
        tip.make_private
        disconnect_all_user_followers(tip)
      end
    end

    def disconnect_all_user_followers(resource = self)
      FOLLOWER_TYPES.each do |follower_type|
        action = follower_type.pluralize + '_followers'
        follower_list = send(action) - [user] # Do not affect the owner
        follower_list.each { |follower| follower.stop_following(resource) }
      end
      resource.share_settings.destroy_all
    end

    def update_resource_followers(topic, settings, params)

      topic.tip_followers.where(user_id: current_user.id).each do |tip|
        tip.share_with_all_relationships(params, current_user)
        tip.update_overrides(settings)
      end
    end

    def extract_overrides(params)
      # returns [{id: 'Everyone', type: 'users'}, {id: 'Following', type: 'users'}]
      list = params['data'].try(:[], 'relationships').try(:[], 'share_settings').try(:[], 'data')
      return [] if list.blank?
      list.select { |users| OVERRIDE_TYPES.include?(users['id']) }
    end

    def following_list(type)
      klass = type.to_s.singularize.camelize.constantize

      followable_ids = follows.where(followable_type: klass.to_s).map(&:followable_id)
      klass.where(id: followable_ids)
    end

    def resource_list(type, json_objects, current_user = nil, params = nil)
      klass = type.to_s.singularize.camelize.constantize

      objects = json_objects.with_indifferent_access

      resources = select_resources_of_type(type, objects)
      resource_list = klass.where(id: resources.map { |resource| resource[:id] })

      unclaimed_objects = resources.reject { |resource| resource_list.map(&:id).include?(resource[:id]) }

      unclaimed_objects.each do |u_obj|
        # Make new resources as needed so we can add them to the list
        # Currently only topics will create new records if they are
        # listed and don't exist
        next unless u_obj.key?(:title)
        next unless klass.new.respond_to?(:parent_id)

        reference_user_id = self.is_a?(User) ? id : user_id
        new_resource = klass.create(title: u_obj[:title], user_id: reference_user_id, parent_id: u_obj[:parent_id])
        new_resource.share_with_all_relationships(params, current_user) if params.present?

        resource_list << new_resource
      end

      resource_list
    end

    def get_ids(type, objects_or_ids)
      return objects_or_ids if objects_or_ids.is_a?(Array)

      json_objects = objects_or_ids.with_indifferent_access
      json_objects[:data] = [json_objects[:data]] if json_objects[:data].is_a?(Hash)
      json_objects = json_objects['data']

      json_objects.map { |object| object['id'] if object['type'].pluralize == type.to_s.pluralize }
    end

    def select_resources_of_type(type, objects)
      # If its a single object, throw it into an array for further processing
      objects[:data] = [objects[:data]] if objects[:data].is_a?(Hash)
      objects[:data].select { |obj| obj[:type].to_s.pluralize == type.to_s.pluralize }
    end

    def follow_ancestry(followable_entity)
      return unless followable_entity.respond_to?(:ancestors)
      return if followable_entity.root?

      followable_entity.ancestors.each do |followable_ancestor|
        follow(followable_ancestor)
      end
    end

    def share_root_with(user_to_share_with)
      return unless self.respond_to?(:root)
      return if self.root?

      user_to_share_with.follow(root)
    end

    def prune_relationships(relationship_type, param_relationships)
      prune_user_followers(param_relationships) if relationship_type == 'users'
      return if self.is_a?(User)

      prune_group_followers(param_relationships) if relationship_type == 'groups'
    end

    def prune_user_followers(param_relationships)
      (user_followers - param_relationships).each { |user| user.stop_following(self) unless user_id == user.id }

      return unless self.respond_to?(:share_settings)
      share_settings.where(sharing_object_type: 'User')
        .where.not(sharing_object_id: param_relationships.map(&:id))
        .destroy_all

      prune_tip_user_followers(param_relationships)
    end

    def prune_group_followers(param_relationships)
      (group_followers - param_relationships).each { |group| group.stop_following(self) }
      return unless self.respond_to?(:share_settings)
      share_settings.where(sharing_object_type: 'Group')
        .where.not(sharing_object_id: param_relationships.map(&:id))
        .destroy_all
    end

    def prune_tip_user_followers(param_relationships)
      user_relationship_ids = param_relationships.select { |r| r.class == User }.map(&:id)
      user_ids_to_remove = current_user_share_ids - user_relationship_ids

      tip_followers.each do |tip|
        user_ids_to_remove.each do |user_to_remove_id|
          follow = Follow.find_by(
            followable_id: tip.id,
            followable_type: 'Tip',
            follower_id: user_to_remove_id,
            follower_type: 'User'
          )
          follow.try(:destroy)
        end
      end
    end

    def current_user_share_ids
      share_settings.where(sharing_object_type: 'User').pluck(:sharing_object_id)
    end

    def invite_relationships(json_objects)
      return if json_objects.blank?

      json_objects.each do |obj|
        user_email = obj['id']

        next if user_email.blank?

        next unless [Topic, Tip].include?(self.class)

        invitation = invitations.find_by(email: user_email)

        invitation.resend! && next if invitation

        invitations.create(
          invitation_type: 'share',
          email: user_email,
          user_id: user_id
        )
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
