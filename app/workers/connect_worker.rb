class ConnectWorker
  include Sidekiq::Worker

  def perform(user_id, followable_id, followable_type)
    user = User.find_by_id user_id

    return unless user

    followable = followable_type.constantize.send(:find_by_id, followable_id)

    return unless followable

    user.connect_with followable
  end
end
