class GroupFollowsSerializer < ActiveModel::Serializer

  has_many :following_tips
  has_many :following_users
  has_many :following_topics

  def following_tips
    object.following_tips.map(&:id).map(&:to_s)
  end

  def following_users
    object.following_users.map(&:id).map(&:to_s)
  end

  def following_topics
    object.following_topics.map(&:id).map(&:to_s)
  end

end
