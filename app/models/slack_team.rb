# == Schema Information
#
# Table name: slack_teams
#
#  id               :integer          not null, primary key
#  team_id          :string           not null
#  domain_id        :integer          not null
#  team_name        :string
#  scope            :string
#  access_token     :string
#  incoming_webhook :text
#  bot              :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_ids         :string           default([]), is an Array
#

class SlackTeam < ActiveRecord::Base
  include Slack::Channel

  belongs_to :domain
  has_many :slack_channels, dependent: :destroy
  has_many :slack_members, dependent: :destroy
  has_many :slack_topic_connections, dependent: :destroy

  validates :team_id, presence: true
  validates :team_name, presence: true
  validates :domain_id, presence: true

  serialize :bot
  serialize :incoming_webhook

  def add_slack_member(data, options = {})
    return [nil, 'Invalid information'] if data[:id].blank?

    slack_member = slack_members.find_by(slack_member_id: data[:id])
    slack_member ||= slack_members.build(slack_member_id: data[:id])

    slack_member[:name] = data[:real_name]
    profile = data[:profile]
    slack_member[:gravatar_url] = profile[:image_48]
    user = options[:integration] ? options[:current_user] : get_user(profile)
    slack_member.user = user
    slack_member.save ? [slack_member, 'Success'] : [nil, slack_member.errors.full_messages]
  end

  def add_slack_channel(data)
    return [nil, 'Invalid information'] if data[:slack_channel_id].blank?

    slack_channel = slack_channels.find_by(slack_channel_id: data[:slack_channel_id])
    slack_channel ||= slack_channels.build(
      slack_channel_id: data[:slack_channel_id], name: data[:name]
    )

    slack_channel.save ? [slack_channel, 'Success'] : [nil, slack_channel.errors.full_messages]
  end

  def get_user(profile)
    user = User.find_by(email: profile[:email])
    user ||= create_user(profile)
  end

  def create_user(profile)
    User.new(first_name: profile[:first_name], last_name: profile[:last_name], email: profile[:email])
  end
end
