# == Schema Information
#
# Table name: slack_topic_connections
#
#  id               :integer          not null, primary key
#  slack_team_id    :integer
#  slack_channel_id :integer
#  topic_id         :string           indexed
#  domain_id        :integer
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class SlackTopicConnection < ActiveRecord::Base
  include Connectable::Model

  belongs_to :slack_team
  belongs_to :slack_channel
  belongs_to :topic

  validates :slack_team_id, presence: true
  validates :slack_channel_id, presence: true
  validates :topic_id, presence: true
end
