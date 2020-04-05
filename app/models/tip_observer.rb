class TipObserver < ActiveRecord::Observer
  def after_create(tip)
    tip.user.reload if Rails.env == 'test'
    tip.user.user_profile.increment_counter('total_tips')

    # UNUSED AS OF 2017-03-02 BECAUSE WE REQUIRE TIPS WITHIN TOPICS
    # AND THAT HAS ITS OWN OBSERVER: THE FOLLOW OBSERVER
    # WITH A DIFFERENT NOTIFICATION
    # NotificationWorker.perform_in(1.second, 'someone_adds_tip', tip.id, tip.class.to_s)
  end

  def after_destroy(tip)
    tip.user.user_profile.decrement_counter('total_tips')
  end
end
