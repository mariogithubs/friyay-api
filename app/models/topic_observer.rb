class TopicObserver < ActiveRecord::Observer
  def after_create(topic)
    return unless topic.is_root?

    if Rails.env.test?
      ActivityNotification.send('someone_adds_topic', topic)
    else
      NotificationWorker.perform_in(1.second, 'someone_adds_topic', topic.id, topic.class.to_s)
    end
  end
end
