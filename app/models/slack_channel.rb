# == Schema Information
#
# Table name: slack_channels
#
#  id               :integer          not null, primary key
#  name             :string
#  slack_channel_id :string
#  slack_team_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class SlackChannel < ActiveRecord::Base
  belongs_to :slack_team
  has_many :slack_topic_connections

  validates :slack_channel_id, presence: true, uniqueness: { scope: :slack_team_id }
end
