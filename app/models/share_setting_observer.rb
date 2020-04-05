class ShareSettingObserver < ActiveRecord::Observer
  def after_save(share_setting)
    return unless share_setting.sharing_object_type == 'User'
    return if share_setting.source == 'invitation'

    case share_setting.shareable_object_type
    when 'Topic'
      event = 'someone_shared_topic_with_me'
    when 'Tip'
      event = 'someone_shared_tip_with_me'
    when 'Question'
      event = 'someone_shared_question_with_me'
    end

    NotificationWorker.perform_in(90.seconds, event, share_setting.id, share_setting.class.to_s)
  end

  def after_create(share_setting)
    return unless share_setting.sharing_object_type == 'User'
    case share_setting.shareable_object_type
    when 'Topic'
      User.find(share_setting.sharing_object_id).follow(Topic.find(share_setting.shareable_object_id))
    when 'Tip'
      User.find(share_setting.sharing_object_id).follow(Tip.find(share_setting.shareable_object_id))
    end
  end
end
