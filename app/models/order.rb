# == Schema Information
#
# Table name: orders
#
#  id         :integer          not null, primary key
#  title      :string
#  is_public  :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Order < ActiveRecord::Base
	has_many :users
	has_many :topic_orders
end
