class SlackMemberWorker
  include Sidekiq::Worker

  def perform(slack_team)
    slack_team = SlackTeam.find_by(id: slack_team)

    return unless slack_team
    slack_team.update_members
  end
end
