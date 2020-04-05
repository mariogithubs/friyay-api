# == Schema Information
#
# Table name: context_topics
#
#  id         :integer          not null, primary key
#  context_id :string
#  topic_id   :integer          not null, indexed
#  position   :integer          indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContextTopic < ActiveRecord::Base
  belongs_to :topic
  belongs_to :context

  acts_as_list scope: :context
end
