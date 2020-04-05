# == Schema Information
#
# Table name: slack_members
#
#  id              :integer          not null, primary key
#  name            :string
#  slack_member_id :string
#  slack_team_id   :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  gravatar_url    :string
#  user_id         :integer
#

class SlackMember < ActiveRecord::Base
  belongs_to :slack_team
  belongs_to :user

  validates :slack_member_id, presence: true, uniqueness: { scope: :slack_team_id }
end
