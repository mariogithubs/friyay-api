class UserFollowsSerializer < ActiveModel::Serializer

  has_many :following_tips
  has_many :following_users
  has_many :following_topics
  has_many :topics_shared_with_user

  def following_tips
    object.following_tips.map(&:id).map(&:to_s)
  end

  def following_users
    object.following_users.map(&:id).map(&:to_s)
  end

  def following_topics
    object.following_topics.map(&:id).map(&:to_s)
  end

  def topics_shared_with_user
    shared_topics = object.share_settings.where(shareable_object_type: "Topic")
    shared_topics.map(&:id).map(&:to_s)
  end  

end
