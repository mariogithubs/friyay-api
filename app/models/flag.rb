# == Schema Information
#
# Table name: flags
#
#  id             :integer          not null, primary key
#  flaggable_id   :integer          indexed
#  flaggable_type :string           indexed
#  flagger_id     :integer          indexed
#  flagger_type   :string           indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  reason         :string
#

class Flag < ActiveRecord::Base
  belongs_to :flaggable, polymorphic: true
  belongs_to :flagger, polymorphic: true

  after_create :notify_admin

  private

  def notify_admin
    AdminMailer.delay.flag(id)
  end
end
