module SlackActions
  extend ActiveSupport::Concern

  API_URL = 'https://slack.com/api'

  def do_add_card params
    begin
     add_card_form = {
        dialog: {
          callback_id: "save_card",
          title: "Add Card",
          submit_label: "Save",
          notify_on_cancel: true,
          state: "saving_card",
          elements: [
            {
                type: "text",
                label: "Card Title",
                name: "card_title"
            },
            {
                type: "textarea",
                label: "Card Description",
                name: "card_desc",
                value: params[:callback_id] === 'add_card_action' ? params[:message][:text] : '' 
            },
            {
                type: "select",
                label: "Topic Selection",
                name: "topic_selection",
                data_source: "external",
            },
            {
                type: "select",
                label: "Share Selection",
                name: "share_selection",
                data_source: "external",
            }
          ]
        },
      trigger_id: params[:trigger_id]
      }
      client.dialog_open(add_card_form)
     rescue Slack::Web::Api::Errors::SlackError => e
      render json: { text: e.message }
   end
  end

  def conversations_info data
    post("#{API_URL}/conversations.info", data)
  end

  def users_info data
    post("#{API_URL}/users.info", data)
  end

  def send_response url, body
    post(url, body.to_json, { 'Content-Type' => 'application/json' } )
  end

  def post_message data
    post("#{API_URL}/chat.postMessage", data)
  end

  private

  def client
    @_client ||= ::Slack::Web::Client.new
  end

  def post url, body, headers = {}
    HTTParty.post(url, body: body, headers: headers)
  end

end