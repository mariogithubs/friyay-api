module Slack
  module Api
    include HTTParty

    MESSAGE_COUNT = 5

    base_uri 'https://slack.com/api'

    def self.options
      {
        client_id: ENV['SLACK_APP_ID'],
        client_secret: ENV['SLACK_APP_SECRET']
      }
    end

    def self.channel_history(channel_id, stamp, token)
      payload = options.merge(channel: channel_id, latest: stamp, count: MESSAGE_COUNT, token: token)

      response = post('/channels.history', body: payload)

      format_messages(response.parsed_response['messages'])
    end

    def self.channel_list(token)
      payload = options.merge({ token: token })

      response = post('/channels.list', body: payload)

      format_channels(response.parsed_response['channels'])
    end

    def self.member_list(token)
      payload = options.merge({ token: token })

      response = post('/users.list', body: payload)

      format_members(response.parsed_response['members'])
    end

    protected

    def self.format_channels(arr)
      return unless arr

      arr.collect { |channel| { name: channel['name'], id: channel['id'] } }
    end

    def self.format_messages(arr)
      return unless arr

      (arr.collect { |message| { id: message['user'], text: message['text'], ts: message['ts'] } })
    end

    def self.format_members(arr)
      return unless arr
      arr.collect { |member| { name: member['name'], id: member['id'], gravatar: member['profile']['image_32'] } }
    end
  end
end
