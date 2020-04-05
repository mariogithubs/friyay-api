class NotificationEmailWorker
  include Sidekiq::Worker

  def perform(action, params, opts = {})
    SendGridMailer.new(action, params, opts).deliver if action_to_send_grid.include?(action)
    return if action_to_send_grid.include?(action)

    NotificationMailer.send(action, params, opts).deliver_now
  end

  def action_to_send_grid
    %w(
      someone_mentioned_on_comment
    )
  end
end
