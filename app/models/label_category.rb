# == Schema Information
#
# Table name: label_categories
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class LabelCategory < ActiveRecord::Base
    belongs_to :user
    validates :name, :presence => true, :uniqueness => true
	has_and_belongs_to_many :labels, join_table: :labels_label_categories

end
