# == Schema Information
#
# Table name: people_orders
#
#  id         :integer          not null, primary key
#  name       :string
#  order      :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PeopleOrder < ActiveRecord::Base
	has_many :user_topic_people_order, dependent: :destroy
	has_many :users, :through => :user_topic_people_order
	has_one :topic, dependent: :nullify
end
