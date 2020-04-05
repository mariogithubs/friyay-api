class SlackMessageWorker
  include Sidekiq::Worker

  def perform(slack_link)
    slack_link = SlackLink.find_by(id: slack_link)

    return unless slack_link
    slack_link.update_messages
  end
end
