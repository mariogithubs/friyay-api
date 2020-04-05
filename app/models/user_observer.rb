class UserObserver < ActiveRecord::Observer
  def after_create(user)
    NotificationWorker.perform_in(5.seconds, 'welcome', user.id, user.class.to_s)
  end
end
