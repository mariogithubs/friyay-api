module Slack
  module Channel
    extend ActiveSupport::Concern

    include Slack::Api

    included do
      after_save :enqueue_updates
    end

    def enqueue_updates
      return if current_domain.public_domain?

      SlackChannelWorker.perform_in(30.seconds, id)
      SlackMemberWorker.perform_in(30.seconds, id)
    end

    def update_channels
      channels = channel_list

      return unless channels

      channels.each do |channel|
        slack_channels.create(name: channel[:name], slack_channel_id: channel[:id])
      end
    end

    def channel_list
      return if access_token.blank?

      return [name: 'development', id: 'C029M7AN8'] if Rails.env.test?

      Slack::Api.channel_list(access_token)
    end

    def update_members
      members = member_list

      return unless members

      members.each do |member|
        smember = slack_members.find_or_initialize_by(slack_member_id: member[:id])
        smember.name = member[:name]
        smember.gravatar_url = member[:gravatar]
        smember.save
      end
    end

    def member_list
      return if access_token.blank?

      return [name: 'payaldhupar', id: 'U029KET3T'] if Rails.env.test?

      Slack::Api.member_list(access_token)
    end

    def current_domain
      Domain.find_by(tenant_name: Apartment::Tenant.current) ||
        Domain.new(tenant_name: 'public', join_type: 'open')
    end
  end
end
