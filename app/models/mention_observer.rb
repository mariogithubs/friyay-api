class MentionObserver < ActiveRecord::Observer
  def after_create(mention)
    NotificationWorker.perform_in(1.second, 'someone_mentioned_on_comment', mention.id, mention.class.to_s)
  end
end
