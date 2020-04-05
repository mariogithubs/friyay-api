# == Schema Information
#
# Table name: user_topic_people_orders
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  topic_id        :integer
#  people_order_id :integer
#

class UserTopicPeopleOrder < ActiveRecord::Base
	belongs_to :user
	belongs_to :topic
	belongs_to :people_order
end
