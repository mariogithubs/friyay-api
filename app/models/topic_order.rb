# == Schema Information
#
# Table name: topic_orders
#
#  id             :integer          not null, primary key
#  subtopic_order :string           default([]), is an Array
#  tip_order      :string           default([]), is an Array
#  topic_id       :integer          not null, indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  is_default     :boolean          default(FALSE)
#

class TopicOrder < ActiveRecord::Base
    belongs_to :topic
    has_and_belongs_to_many :sub_topic_orders, class_name: "Topic", 
                                     join_table: "topic_orders_topics"

    has_and_belongs_to_many :tips, join_table: "topic_orders_tips"
    has_and_belongs_to_many :users, join_table: "topic_orders_users"

    def update_associations(params)
      sub_topics = params[:attributes][:subtopic_order]
      tips = params[:attributes][:tip_order]

      self.tips = Tip.where(:id => tips)
      self.sub_topic_orders = Topic.where(:id => sub_topics)
    end

    def user_relationship(user_id)
      self.users = User.where(id: user_id)
    end

    def set_default_order(params)
      TopicOrder.where(topic_id: params[:attributes][:topic_id]).update_all(is_default: false)
      TopicOrder.find(self.id).update(is_default: true)
    end                                                                      
end
