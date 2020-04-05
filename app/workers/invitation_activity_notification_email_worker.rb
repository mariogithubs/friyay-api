class InvitationActivityNotificationEmailWorker
  include Sidekiq::Worker

  def perform(action, params, opts = {})
    InvitationActivityNotificationMailer.send(action, params, opts).deliver
  end
end
