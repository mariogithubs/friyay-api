# == Schema Information
#
# Table name: label_orders
#
#  id         :integer          not null, primary key
#  name       :string
#  order      :integer          default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class LabelOrder < ActiveRecord::Base
	has_many :user_topic_label_order, dependent: :destroy
	has_many :users, :through => :user_topic_label_order
	has_one :topic, dependent: :nullify
end
