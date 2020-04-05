# == Schema Information
#
# Table name: user_topic_label_orders
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  topic_id       :integer
#  label_order_id :integer
#

class UserTopicLabelOrder < ActiveRecord::Base
	belongs_to :user
	belongs_to :topic
	belongs_to :label_order
end
