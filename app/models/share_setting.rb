# == Schema Information
#
# Table name: share_settings
#
#  id                    :integer          not null, primary key
#  user_id               :integer          indexed
#  shareable_object_type :string           indexed => [shareable_object_id], indexed
#  shareable_object_id   :integer          indexed => [shareable_object_type], indexed
#  sharing_object_type   :string           indexed => [sharing_object_id], indexed
#  sharing_object_id     :integer          indexed => [sharing_object_type], indexed
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  source                :string
#

class ShareSetting < ActiveRecord::Base
  belongs_to :user
  belongs_to :sharing_object, polymorphic: true
  belongs_to :shareable_object, polymorphic: true

  validates :user_id, presence: true
end
