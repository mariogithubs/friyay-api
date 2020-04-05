# == Schema Information
#
# Table name: topic_users
#
#  id          :integer          not null, primary key
#  follower_id :integer          not null, indexed => [status, topic_id]
#  user_id     :integer          not null
#  topic_id    :integer          not null, indexed => [status, follower_id]
#  status      :integer          default(0), not null, indexed => [follower_id, topic_id]
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class TopicUser < ActiveRecord::Base
  enum status: {
    show: 0,
    block: 1
  }
end
