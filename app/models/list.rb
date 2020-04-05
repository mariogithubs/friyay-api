# == Schema Information
#
# Table name: lists
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null, indexed
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class List < ActiveRecord::Base
  include Connectable::Model

  acts_as_followable
  acts_as_follower

  belongs_to :user

  validates :user_id, presence: true
end
