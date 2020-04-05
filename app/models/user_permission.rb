# == Schema Information
#
# Table name: activity_permissions
#
#  id               :integer          not null, primary key
#  permissible_type :string
#  permissible_id   :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  topic_id         :integer
#  type             :string           default("DomainPermission")
#  access_hash      :text             default({})
#

class UserPermission < ActivityPermission
end
