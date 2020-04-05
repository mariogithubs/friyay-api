module Slack
  module History
    extend ActiveSupport::Concern

    include Slack::Api

    included do
      after_save :enqueue_update_slack_messages
    end

    def enqueue_update_slack_messages
      return if current_domain.public_domain?

      SlackMessageWorker.perform_in(30.seconds, id)
    end

    def update_messages
      msgs = channel_history

      return if msgs.blank?

      update_column :messages, msgs
    end

    def channel_history
      return if setup_unavailable?

      return I18n.t('slack.dummy_messages') if Rails.env.test?

      history = Slack::Api.channel_history(channel_id, timestamp, access_token)

      return if history.blank?

      txt = history.collect { |message| format_message(message) }.join('')

      "<div class='message row'>#{formatted_with_names(txt)}</div><div class='col-xs-12'><hr></div>"
    end

    def format_message(message)
      time = DateTime.strptime(message[:ts], '%s')
      shorttime = time.strftime('%m/%d %I:%M %p')

      user = "<div class='slack-message-left col-md-1'>#{message[:id]}</div>"
      time = "<div class='slack-message-right col-md-11'><strong class='slack-message-user'>#{message[:id]}</strong><span class='slack-message-ts text-muted small'> #{shorttime}</span>"
      body = "<div class='slack-message-body'>#{message[:text]}</div></div>"

      user + time + body
    end

    def formatted_with_names(txt)
      return txt if txt.blank?

      team.slack_members.each do |member|
        txt.gsub!(member.slack_member_id, "#{member.name}")
        txt.gsub!(
          "<div class='slack-message-left col-md-1'>#{member.name}</div>",
          "<div class='slack-message-left col-md-1'><img src='#{member.gravatar_url}' /></div>"
        )
      end

      txt
    end

    def setup_unavailable?
      timestamp.blank? || access_token.blank? || channel_id.blank?
    end

    def timestamp
      ts = file.split('/').last

      return unless ts

      "#{ts[1, 10]}.#{ts[11, ts.length - 1]}"
    end

    def channel_id
      arr = file.split('/')

      channel_name = arr[arr.length - 2]

      team.slack_channels.find_by(name: channel_name).try :slack_channel_id
    end

    def team
      current_domain.slack_teams.first
    end

    def access_token
      team.try :access_token
    end

    def current_domain
      Domain.find_by(tenant_name: Apartment::Tenant.current) ||
        Domain.new(tenant_name: 'public', join_type: 'open')
    end
  end
end
