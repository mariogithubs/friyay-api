# == Schema Information
#
# Table name: view_assignments
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  view_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  domain_id  :integer
#

class ViewAssignment < ActiveRecord::Base
    belongs_to :user
    belongs_to :view

    validates :view_id, uniqueness: { scope: [:user_id, :domain_id] }

end
