# == Schema Information
#
# Table name: comments
#
#  id                 :integer          not null, primary key
#  commentable_id     :integer          indexed, indexed => [commentable_type]
#  commentable_type   :string           indexed => [commentable_id], indexed
#  title              :string
#  body               :text
#  subject            :string
#  user_id            :integer          not null, indexed
#  parent_id          :integer
#  lft                :integer
#  rgt                :integer
#  longitude          :float
#  latitude           :float
#  address            :string
#  location           :string
#  created_at         :datetime
#  updated_at         :datetime
#  message_identifier :string
#

class Comment < ActiveRecord::Base
  include ActsAsFlaggable
  include Parse
  include Mentionable

  acts_as_nested_set scope: [:commentable_id, :commentable_type]
  acts_as_votable

  validates :body, presence: true
  validates :user, presence: true

  belongs_to :commentable, polymorphic: true
  belongs_to :user
  has_many :mentions, as: :mentionable

  # TODO: Move these long scopes into class methods
  scope :find_comments_by_user, lambda { |user|
    where(user_id: user.id).order('created_at DESC')
  }

  scope :find_comments_for_commentable, lambda { |commentable_str, commentable_id|
    where(commentable_type: commentable_str.to_s, commentable_id: commentable_id).order('created_at DESC')
  }

  before_create :generate_message_identifier

  def children?
    children.any?
  end

  def reply_with(body)
    attributes = {
      commentable: commentable,
      body: body,
      user_id: user_id
    }

    children.create(attributes)
  end

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    new \
      commentable: obj,
      body: comment,
      user_id: user_id
  end

  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def generate_message_identifier
    self.message_identifier = SecureRandom.hex(13)
  end
end
