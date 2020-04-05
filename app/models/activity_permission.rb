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

class ActivityPermission < ActiveRecord::Base
  belongs_to :permissible, polymorphic: true

  before_create :set_default

  serialize :access_hash, Hash

  DEFAULT_ACCESS_HASH = {
    create_topic:     { roles: ['member', 'power'] },
    edit_topic:       {},
    destroy_topic:    {},

    create_tip:       { roles: ['member', 'power'] },
    edit_tip:         { roles: ['member', 'power'] },

    destroy_tip:      { roles: ['member', 'power'] },
    like_tip:         { roles: ['member', 'power'] },
    comment_tip:      { roles: ['member', 'power'] },

    create_group:     { roles: ['member', 'power'] },
    edit_group:       { roles: ['member', 'power'] },
    destroy_group:    { roles: ['member', 'power'] }
  }

  def set_default
    access_hash = DEFAULT_ACCESS_HASH
    access_hash
  end
end
