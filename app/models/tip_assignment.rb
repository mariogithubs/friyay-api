# == Schema Information
#
# Table name: tip_assignments
#
#  id              :integer          not null, primary key
#  assignment_id   :integer          indexed
#  tip_id          :integer          indexed
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  assignment_type :string           indexed
#

class TipAssignment < ActiveRecord::Base
  # belongs_to :user
  # belongs_to :group
  belongs_to :assignment, polymorphic: true
  belongs_to :tip
  
end
