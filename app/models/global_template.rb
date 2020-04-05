# == Schema Information
#
# Table name: public.global_templates
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  template_type :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class GlobalTemplate < ActiveRecord::Base
  belongs_to :user

  def self.suggested_topics
    where(template_type: 'Topic').where.not(title: Topic.pluck(:title))
  end
end
