# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  notifier_id     :integer
#  type            :string
#  action          :string
#  notifiable_type :string           indexed => [notifiable_id]
#  notifiable_id   :integer          indexed => [notifiable_type]
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email_sent_at   :datetime
#  read_at         :datetime
#  is_processed    :boolean          default(FALSE)
#  frequency       :string
#  send_email      :boolean          default(TRUE)
#  invitation_id   :integer          indexed
#

class Notification < ActiveRecord::Base
  attr_accessor :custom_opts

  has_paper_trail
  acts_as_readable on: :email_sent_at

  belongs_to :user
  belongs_to :notifier, class_name: 'User'
  belongs_to :notifiable, polymorphic: true
  belongs_to :invitation

  validates :type, presence: true
  validates :action, presence: true
  # Doesn't need to have user, we notify invitee too
  # validates :user, presence: true

  after_create :enqueue_email, :post_to_slack

  FREQUENCY = %w(always daily weekly never)
  LIVE_NOTIFICATION_TYPE = %w(someone_comments_on_tip someone_commented_on_tip_user_commented someone_likes_tip someone_mentioned_on_comment someone_shared_topic_with_me someone_adds_topic)

  def self.unsent_feed_since(frequency)
    where(
      'is_processed is false and email_sent_at IS NULL and frequency = ?',
      frequency
    )
  end

  class << self
    def expire_old_email_notifications(frequency)
      current_time = Time.zone.now
      return if current_time.sunday? || current_time.monday?

      old_notifications = where(
        'email_sent_at < ?',
        current_time.beginning_of_day
      ).where(
        is_processed: false,
        send_email: true,
        frequency: frequency
      )

      old_notifications.update_all(is_processed: true)
    end
  end

  private

  def enqueue_email
    set_notification_frequency
    return if action == 'tip_feed'
    return if user_id.blank? || invitation_id.present? # do not enqueue if notification for invitee
    return unless notification_is_set_to_always
    update_attributes(is_processed: true, email_sent_at: Time.zone.now)

    NotificationEmailWorker.perform_in(20.seconds, action, id, custom_opts) if send_email
  end

  def action_frequency
    return unless user && user.user_profile
    user.user_profile.settings(:email_notifications).send(action)
  end

  def set_notification_frequency
    # TODO: Change email_sent_at to email_send_at for clarity
    self.frequency = action_frequency if action_frequency.present?
    # today = Time.zone.now
    # case frequency
    # when 'daily'
    #   self.email_sent_at = 5.hours.ago(today.end_of_day)
    # when 'weekly'
    #   self.email_sent_at = 5.hours.ago(2.days.ago(today.end_of_week))
    # end
    save
  end

  def notification_is_set_to_always
    !action_frequency || (action_frequency.to_s == 'always')
  end

  def post_to_slack
    return unless LIVE_NOTIFICATION_TYPE.include?(self.action)
    user = self.user
    slack_teams = SlackTeam.where("'#{user.id}' = ANY (user_ids)")
    slack_teams.each do |slack_team|
      slack_member = SlackMember.find_by(slack_member_id: slack_team.bot[:bot_user_id]) if slack_team.bot.present?
      return unless slack_member.present?
      set_data = set_slack_data
      slack_options = {
        response_type: "in_channel",
        text: set_data[0],
        channel: slack_member.slack_member_id,
        as_user: true,
        token: slack_team.access_token,
        title: set_data[0],
        attachments: set_data[1]
      }
      slack_response = post_message slack_options
    end
  end

  def set_slack_data
    case self.action
    when "someone_comments_on_tip"
      tip = self.notifiable.commentable
      title = "Someone just commented on your Card: #{tip.title}",
      attachments = add_attachment_for_tip(tip)
    when "someone_commented_on_tip_user_commented"  
      tip = self.notifiable.commentable
      title = "Someone just commented on a Card you commented on: #{tip.title}",
      attachments = add_attachment_for_tip(tip)
    when "someone_likes_tip"
      tip = self.notifiable.votable
      title = "Someone just liked your Card: #{tip.title}",
      attachments = add_attachment_for_tip(tip)
    when "someone_mentioned_on_comment"
      tip = self.notifiable.commentable
      title = "Someone mentioned on comment",
      attachments = add_attachment_for_tip(tip)
    when "someone_shared_topic_with_me"
      topic = self.notifiable
      title = "#{self.notifier.name} just shared a Topic with you",
      attachments = add_attachment_for_topic(topic)
    when "someone_adds_topic"
      topic = self.notifiable
      title = "#{self.notifier.name} just added a topic to #{@domain.tenant_name}",
      attachments = add_attachment_for_topic(topic)
    end
  end

  def add_attachment_for_tip(tip)
    [
      {
        title: tip.title,
        title_link: "https://#{domain_host}/cards/#{tip.slug}",
        fallback: tip.title + " - https://#{domain_host}/cards/#{tip.slug}",
      }
    ].to_json
  end

  def add_attachment_for_topic(topic)
    [
      {
        title: topic.title,
        title_link: "https://#{domain_host}/topics/#{topic.slug}",
        fallback: topic.title + " - https://#{domain_host}/topics/#{topic.slug}",
      }
    ].to_json
  end

  def post_message data
    HTTParty.post("#{SlackActions::API_URL}/chat.postMessage",body: data)
  end

  def domain_host
    return ENV['TIPHIVE_HOST_NAME'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}.#{ENV['TIPHIVE_HOST_NAME']}"
  end
end
