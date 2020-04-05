class InvitationEmailWorker
  include Sidekiq::Worker

  def perform(action, id, connectable_user_id = nil)
    if connectable_user_id
      InvitationMailer.send(action, id, connectable_user_id).deliver_now
    else
      InvitationMailer.send(action, id).deliver_now
    end
  end
end
