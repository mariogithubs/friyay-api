class NotificationSerializer < ActiveModel::Serializer
  attributes :action, :is_processed, :read_at, :frequency, :date, :time

  belongs_to :user
  belongs_to :notifier, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  def user
    receiver = object.user

    build_user_data(receiver)
  end

  def notifier
    build_user_data(object.notifier)
  end

  def notifiable
    case object.action
    when 'someone_comments_on_tip'
      build_comment_data(object.notifiable)
    when 'someone_mentioned_on_comment'
      build_comment_data(object.notifiable)
    when 'someone_commented_on_tip_user_commented'
      build_comment_data(object.notifiable)  
    when 'someone_likes_tip'
      build_tip_data(object.notifiable.votable)
    when 'someone_shared_topic_with_me'
      build_topic_data(object.notifiable.shareable_object)
    when 'someone_adds_topic'
      build_topic_data(object.notifiable)
    else
      object.notifiable
    end
  end

  def build_user_data(user)
    {
      id:         user.id,
      name:       user.name,
      username:   user.username,
      avatar_url: user.avatar.square.url
    }
  end

  def build_comment_data(comment)
    {
      id: comment.id,
      body: comment.body,
      tip: {
        data: build_tip_data(comment.commentable)
      }
    }
  end

  def build_tip_data(tip)
    if tip.topics.count > 0
      topic = tip.topics.first

      topic_data = {
        data: build_topic_data(topic)
      }
    end

    {
      id: tip.id,
      title: tip.title,
      slug: tip.slug,
      topic: topic_data
    }
  end

  def build_topic_data(topic)
    {
      id:    topic.id,
      title: topic.title,
      slug:  topic.slug
    }
  end

  def date
    object.created_at.to_date
  end

  def time
    object.created_at.time
  end
end
