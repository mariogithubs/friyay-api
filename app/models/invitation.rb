# == Schema Information
#
# Table name: invitations
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null, indexed
#  email            :string
#  invitation_token :string
#  invitation_type  :string
#  invitable_type   :string
#  invitable_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  custom_message   :text
#  state            :string           default("pending")
#  first_name       :string
#  last_name        :string
#  do_not_remind    :boolean          default(FALSE)
#  daily_sent_at    :datetime
#  options          :jsonb            default({}), not null, indexed
#

class Invitation < ActiveRecord::Base
  include Connectable::Model

  INVITATION_TYPES = %w(account hive domain group share guest admin)
  # Types should probably be account, domain, hive, group, share
  # and we should have member types of guest, admin, member
  # a member type of member is the default

  belongs_to :user
  belongs_to :invitable, polymorphic: true

  has_many :notifications, dependent: :destroy

  validates :user, :email, presence: true
  validates :invitation_token, :invitation_type, presence: true

  before_validation :generate_invitation_token

  after_create :send_email_or_connect

  delegate :email, to: :user, prefix: :from
  delegate :name, to: :user, prefix: true, allow_nil: true

  scope :pending, -> { where('do_not_remind is false and state = ?', 'pending') }

  def title
    invitable ? invitable.title : 'Friyay'
  end

  def domain_name
    Domain.find_by(tenant_name: Apartment::Tenant.current).try(:name) || 'Friyay'
  end

  def hosturl
    return "#{invitable.tenant_name.downcase}" + '.' + ENV['TIPHIVE_HOST_NAME'] if invitable && invitable.is_a?(Domain)
    return ENV['TIPHIVE_HOST'] if Apartment::Tenant.current == 'public'

    "#{Apartment::Tenant.current}" + '.' + ENV['TIPHIVE_HOST_NAME']
  end

  def url
    [hosturl, (invitable.try :invite_url)].join('')
  end

  def self.accept(token, user)
    invitation = Invitation.find_by_invitation_token(token)
    return unless invitation
    invitation.connect(user)
  end

  def connect(connectable_user)
    # REFACTOR: move to connectable library? or a better place?
    return true if accepted

    case invitation_type
    when 'account'
      connect_to_domain(connectable_user) unless Apartment::Tenant.current == 'public'
    when 'group'
      # TODO: Ensure user is connected to the domain that the group is in before add_member
      # something like domain = Domain.find(group.domain_id) or whatever
      # Then connectable_user.join(domain)

      # invitable.add_member(connectable_user)
    when 'domain', 'guest' # domain == member
      connectable_user.join(invitable, as: invitation_type, invitation_id: id)
      connect_resources(connectable_user, options) unless Apartment::Tenant.current == 'public'
    when 'share'
      connect_to_domain(connectable_user) unless Apartment::Tenant.current == 'public'
      invitable.share_with_relationships('users', data: [{ id: connectable_user.id, type: 'users' }])
    end

    connect_to_resource(connectable_user) # Connects to the person inviting
    accept!

    InvitationEmailWorker.perform_in(1.minute, 'accept', id, connectable_user.id)
    true
  end

  def connect_resources(connectable_user, options)
    share_users(connectable_user, options['users']) if options.key?('users')
    share_groups(connectable_user, options['groups']) if options.key?('groups')
    share_topics(connectable_user, options['topics']) if options.key?('topics')
    share_tips_from(connectable_user, options['topics']) if options.key?('topics')
  end

  def share_users(connectable_user, options_user)
    user_ids = options_user.include?('all') ? DomainMember.all.pluck(:id) : options_user
    return if user_ids.blank?
    connectable_user.follow_resources('User', user_ids)
  end

  def share_groups(connectable_user, group_ids)
    return if group_ids.blank?
    connectable_user.follow_resources('Group', group_ids)
  end

  def share_topics(connectable_user, topics)
    return if topics.blank?

    requested_topic_ids = topics.map { |topic| topic['id'] }

    if requested_topic_ids.include?('all')
      actual_topic_ids = Topic.all.pluck(:id)
    else
      actual_topic_ids = requested_topic_ids
      topics.each do |topic|
        subtopics = Topic.where("ancestry='#{topic['id']}' OR ancestry LIKE '%/#{topic['id']}'").map { |subtopic| { "id" => subtopic.id, "tips" => topic['tips'] } }
        if subtopics.present?
          share_topics(connectable_user, subtopics)
          share_tips_from(connectable_user, subtopics)
        end
        ShareSetting.create(   
          user_id: user_id,    
          shareable_object_id: topic['id'],   
          shareable_object_type: 'Topic',    
          sharing_object_id: connectable_user.id,    
          sharing_object_type: 'User'    
       )    
     end
    end

    connectable_user.follow_resources('Topic', actual_topic_ids.uniq)
  end

  def share_tips_from(connectable_user, topics)
    return if topics.blank?

    tip_ids = []
    topics.each do |topic|
      next unless topic.key?('tips')

      if topic['tips'].include?('all')
        # Find followers without intermediate finding of Topic
        tip_ids << Follow.where(
          followable_type: 'Topic',
          followable_id: topic['id'],
          follower_type: 'Tip'
        ).pluck(:follower_id)
      else
        tip_ids << topic['tips'].map {|tip_id| tip_id.to_i }
      end
    end

    tip_id_collection = tip_ids.flatten.compact.uniq
    # remove tips that the inviter can't view
    clean_tip_ids = tip_id_collection & user.viewable_tips.pluck(:id)

    return if clean_tip_ids.blank?

    connectable_user.follow_resources('Tip', clean_tip_ids)

    create_tip_share_settings(connectable_user, clean_tip_ids)
  end

  def create_tip_share_settings(connectable_user, tip_id_collection)
    tip_id_collection.each do |tip_id|
      ShareSetting.create(
        user_id: user_id,
        shareable_object_id: tip_id,
        shareable_object_type: 'Tip',
        sharing_object_id: connectable_user.id,
        sharing_object_type: 'User',
        source: 'invitation'
      )
    end
  end

  def reinvite
    InvitationMailer.delay.reinvite(id) if pending && !do_not_remind
  end

  def remind
    InvitationMailer.delay.remind(id) if pending
  end

  def notify(domain)
    InvitationMailer.delay.reminder(id, domain)
    update_attribute :do_not_remind, true
  end

  def self.search_emails(emails)
    emails = [emails] unless emails.is_a?(Array)
    status = []

    emails.each do |e|
      if User.find_by_email(e)
        status << { email: e, status: 'existing member' }
      else
        invitation = Invitation.find_by_email(e)
        status << (invitation ? { email: e, status: invitation.state } : { email: e, status: 'not invited yet' })
      end
    end
    status
  end

  def existing_user
    User.find_by_email(email)
  end

  # TODO: Change these to an enum (invitation.pending? and invitation.pending!)
  def pending
    state == 'pending'
  end

  def accepted
    state == 'accepted'
  end
  alias_method :accepted?, :accepted

  def requested?
    state == 'requested'
  end

  def connect_to_domain(connectable_user)
    domain = Domain.find_by_tenant_name(Apartment::Tenant.current)
    return unless domain
    connectable_user.join(domain, as: invitation_type, invitation_id: id)
  end

  def accept!
    update_attribute :state, :accepted
  end

  def resend!
    send_email_or_connect
  end

  def generate_feed(frequency = 'daily')
    feed = notifications.unsent_feed_since(frequency)
    feed_ids = merge_feed(feed).map(&:id).uniq
    return unless feed_ids.present?
    feed.update_all(is_processed: true)
    case frequency
    when 'daily'
      InvitationActivityNotificationEmailWorker.perform_in(
        60.seconds, 'daily_feed_email', invitation_id: id, notification_ids: feed_ids, email: email
      )
    end
  end

  def merge_feed(feed)
    # Currently only merges tips assigned to topics
    feed_without_tips = feed.dup
    feed_without_tips.to_a.delete_if { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }

    merged_feed = []

    feed.select { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }
      .group_by { |tip_feed_item| tip_feed_item.notifiable.follower.id }
      .each { |_key, group| merged_feed << group.first }

    merged_feed + feed_without_tips
  end

  def self.domain_invite_from_system(email, tenant = 'public')
    domain = Domain.find_by(tenant_name: tenant)
    domain_admin_id = domain.user_id || User.select(:id).find_by(email: 'mscholl87@gmail.com').id

    Apartment::Tenant.switch tenant do
      Invitation.create(
        user_id: domain_admin_id,
        email: email,
        invitation_type: 'domain',
        invitable_id: domain.id,
        invitable_type: 'Domain'
      )
    end
  end

  protected

  def send_email_or_connect
    email_request && return if requested?
    return true unless pending

    if existing_user
      connect(existing_user)

      accept!
    else
      return if Rails.env == 'test'
      InvitationEmailWorker.perform_in(30.seconds, invitation_type, "#{id}")
      InvitationEmailWorker.perform_in(2.days.from_now, 'remind', "#{id}")
    end
  end

  def email_request
    InvitationEmailWorker.perform_in(30.seconds, 'requested', "#{id}")
  end

  def generate_invitation_token
    self.invitation_token = Digest::SHA1.hexdigest("#{email}-#{invitation_type}-#{invitable_type}-#{invitable_id}")
  end
end
