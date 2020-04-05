# == Schema Information
#
# Table name: label_assignments
#
#  id         :integer          not null, primary key
#  label_id   :integer          indexed
#  item_id    :integer          indexed, indexed => [item_type]
#  item_type  :string           indexed, indexed => [item_id]
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class LabelAssignment < ActiveRecord::Base
  validates :label_id, uniqueness: { scope: [:item_id, :item_type] }

  belongs_to :label

  def item
    item_type.constantize.find_by_id(item_id)
  end
end
