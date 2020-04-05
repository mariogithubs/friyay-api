class NotificationWorker
  include Sidekiq::Worker

  def perform(action, object_id, object_type, opts = {})
    object = object_type.constantize.send(:find_by, id: object_id)
    return if object.blank?

    ActivityNotification.send(action, object, opts)

    # Check for supported activities notification to invitee
    return if %w(someone_add_tip_to_topic someone_adds_topic someone_joins_domain).exclude?(action)
    InvitationActivityNotification.send(action, object, opts)
  end
end
