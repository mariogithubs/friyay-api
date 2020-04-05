require 'slack-ruby-bot'

module SlackTipBot
  class Bot < SlackRubyBot::Bot
    include HTTParty

    command 'search' do |client, data, _match|
      results = build_search(data.text, data)

      payload = { channel: data.channel }
      payload[:text] = results?(results) ? results['text'] : '0 tips found!'
      payload[:attachments] = [
        {
          text: results['attachments'] ? results['attachments'][0]['text'] : '0 results!'
        }
      ] if attachments?(results)

      client.web_client.chat_postMessage(payload)
    end

    def self.build_search(text, data)
      headers = { 'X-Tenant-Name' => 'public' }

      response = HTTParty.post(
        'http://api.tiphive.local:3000/v2/slack/search',
        body: {
          token: 'kAzxybs8vyxYt3hIw7nqlCb3',
          text: format_text(text),
          team_id: data[:team],
          channel: data[:channel]
        },
        headers: headers
      )

      # rubocop:disable Lint/UselessAssignment
      response_json = JSON.parse(response.body)
      # rubocop:enable Lint/UselessAssignment

      response.parsed_response
    end

    # rubocop:disable Performance/StringReplacement
    def self.format_text(text)
      text.gsub!('search ', '')
      text.gsub!('"', '')
      text
    end
    # rubocop:enable Performance/StringReplacement

    def self.results?(results)
      !results['text'].blank?
    end

    def self.attachments?(results)
      results['attachments'] && results['attachments'].count > 0
    end
  end
end
