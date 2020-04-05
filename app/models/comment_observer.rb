class CommentObserver < ActiveRecord::Observer
  def after_create(comment)
    comment.user.user_profile.increment_counter('total_comments')

    if comment.commentable_type == 'Question'
      NotificationWorker.perform_in(1.second, 'someone_answered_your_question', comment.id, comment.class.to_s)
    elsif comment.commentable_type == 'Tip'
      NotificationWorker.perform_in(1.second, 'someone_comments_on_tip', comment.id, comment.class.to_s)
    end
    if comment.commentable_type == "Tip"
      comment.commentable.follows.where(followable_type: "Topic").each do |f|
        topic_connections = SlackTopicConnection.where(topic_id: ["All Topics",f.followable.id])
        topic_connections = topic_connections.to_a.uniq(&:slack_channel_id)
        text = "New comment added on card:"
        topic_connections.each do |tc|
          tc.post_to_slack_channel(comment.commentable, f.followable, text )
        end
      end
    end
  end

  def after_destroy(comment)
    comment.user.user_profile.decrement_counter('total_comments')
  end
end
