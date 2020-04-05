class SlackTeamSerializer < ActiveModel::Serializer
  attributes :team_name, :slack_members, :slack_channels
end