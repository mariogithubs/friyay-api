# == Schema Information
#
# Table name: follows
#
#  id              :integer          not null, primary key
#  followable_id   :integer          not null, indexed => [followable_type], indexed
#  followable_type :string           not null, indexed => [followable_id], indexed
#  follower_id     :integer          not null, indexed => [follower_type], indexed
#  follower_type   :string           not null, indexed => [follower_id], indexed
#  blocked         :boolean          default(FALSE), not null, indexed
#  created_at      :datetime
#  updated_at      :datetime
#

class Follow < ActiveRecord::Base
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  attr_accessor :notify

  def block!
    update_attribute(:blocked, true)
  end
end
