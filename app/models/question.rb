# == Schema Information
#
# Table name: questions
#
#  id              :integer          not null, primary key
#  title           :string
#  user_id         :integer          not null, indexed
#  body            :text
#  share_public    :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  share_following :boolean          default(FALSE)
#

class Question < ActiveRecord::Base
  include Adminify
  include Slugger
  include Connectable::Model
  include Filterable
  include ActsAsFlaggable
  include Shareable
  include Permission::Question

  resourcify

  acts_as_followable
  acts_as_follower
  acts_as_commentable
  acts_as_votable

  belongs_to :user

  validates :user, presence: true

  after_create :share_with_creator

  has_many :commenters, source: :user, foreign_key: :user_id, through: :comment_threads

  scope :is_public, -> { where(share_public: true) }
  scope :type_topics, -> { joins(:follows).where(follows: { followable_type: 'Topic' }) }

  searchable do
    text :title, :body
    string :kind do
      self.class.name
    end

    string :tenant_name do
      Apartment::Tenant.current
    end
  end

  # Instance Methods
  def topics
    (following_topics.without_root + Topic.roots_for(subtopics)).uniq
  end

  def subtopics
    following_topics.with_root
  end

  # Class Methods
  def self.from_topics(topic_list)
    type_topics.where(follows: { followable_id: topic_list.ids })
  end

  def self.belonging_to(user_list)
    where(user_id: user_list.ids)
  end

  def notify_like(like)
    NotificationWorker.perform_in(1.second, 'someone_likes_question', like.id, like.class.to_s)
  end

  def viewable_by?(viewer)
    return true if share_public == true
    return true if viewer.following?(self)
    return true if share_following == true && viewer.following?(user)
    return true if share_settings.pluck(:sharing_object_id).include?(viewer.id)

    false
  end
end
