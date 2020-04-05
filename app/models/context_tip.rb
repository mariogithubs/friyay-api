# == Schema Information
#
# Table name: context_tips
#
#  id         :integer          not null, primary key
#  context_id :string
#  tip_id     :integer          not null, indexed
#  position   :integer          indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContextTip < ActiveRecord::Base
  belongs_to :tip
  belongs_to :context

  acts_as_list scope: :context
end
