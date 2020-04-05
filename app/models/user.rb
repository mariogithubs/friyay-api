# == Schema Information
#
# Table name: public.users
#
#  id                     :integer          not null, primary key, indexed
#  email                  :string           default(""), not null, indexed
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string           indexed
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string           indexed
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string           indexed
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string
#  last_name              :string
#  username               :string           not null, indexed
#  order_id               :integer          indexed
#

# TODO: reduce the viewable_tips and viewable_questions
# TODO: refactor this to be a lot smaller
class User < ActiveRecord::Base
  rolify
  acts_as_reader
  acts_as_follower
  acts_as_followable
  acts_as_voter

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  include Connectable::Model
  include Filterable
  include SamlEnabled
  include Join::User
  include Permission::User

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable # , :confirmable

  # Content associations
  has_many :topics
  has_many :attachments
  has_many :tips
  has_many :questions
  has_many :groups
  has_many :answers
  has_many :comments
  has_many :tip_links, dependent: :destroy
  has_many :labels, dependent: :destroy

  # Membership associations - to be removed upon destroy & leave
  has_many :domain_memberships
  has_many :domains, through: :domain_memberships
  has_many :invitations, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_permissions, as: :permissible, dependent: :destroy
  has_many :share_settings, as: :sharing_object, dependent: :destroy
  has_many :tip_assignments, as: :assignment
  has_many :assigned_tips, through: :tip_assignments, source: :tip
  has_many :views
  has_many :view_assignments
  has_many :assigned_views, through: :view_assignments, source: :view
  

  # Global associations - DO NOT remove except if user destroyed
  has_one  :user_profile, dependent: :destroy

  has_many :user_topic_label_order, dependent: :destroy
  has_many :label_orders, :through => :user_topic_label_order
  has_many :user_topic_people_order, dependent: :destroy
  has_many :people_orders, :through => :user_topic_people_order
  has_and_belongs_to_many :topic_orders, join_table: "topic_orders_users"
  has_many :slack_members

  validates :first_name, presence: true, if: :not_recovering_password
  validates :last_name,  presence: true, if: :not_recovering_password
  validates :username,   presence: true, uniqueness: true, if: :not_recovering_password

  validates :password_confirmation, presence: true, if: :password_confirmation_required?
  validate :current_password_for_special_fields, on: :update

  before_create :add_user_profile, :generate_username
  after_create :replace_username

  scope :simple, -> () { select(:id, :email, :first_name, :last_name) }
  scope :active, -> () { joins(:domain_memberships).where(domain_memberships: { active: true }) }

  has_paper_trail on: [:destroy]

  searchable do
    text :name, :title
    string(:name) { name.downcase }

    string :kind do
      self.class.name
    end

    # string :domains, multiple: true do
    #   domains.pluck(:tenant_name)
    # end
    string :tenant_name do
      Apartment::Tenant.current
    end
  end

  delegate :avatar, to: :user_profile, allow_nil: true

  attr_accessor :current_password, :is_password_reset

  def auth_token
    JsonWebToken.encode(user_id: id, user_email: email, user_first_name: first_name, user_last_name: last_name)
  end

  def name
    "#{first_name} #{last_name}"
  end
  alias_method :title, :name

  def guest_domains
    guest_memberships = domain_memberships.where(role: 'guest')
    return [] if guest_memberships.blank?

    guest_memberships.map(&:domain)
  end

  def follow!(followable)
    return if self == followable

    local_follow = follows.find_by(followable_id: followable.id, followable_type: parent_class_name(followable))
    local_follow ||= follows.build(followable_id: followable.id, followable_type: parent_class_name(followable))
    local_follow.notify = false
    local_follow.save
  end

  def admin?
    email == 'anthonylassiter@gmail.com'
  end

  def join(resource, opts = { as: 'member' })
    domain = resource.is_a?(String) ? Domain.find_by(tenant_name: resource) : resource

    membership = MembershipService.new(domain, self)
    membership.join(opts)
  end

  def leave(resource, opts = { as: 'member' })
    domain = resource.is_a?(String) ? Domain.find_by(tenant_name: resource) : resource

    membership = MembershipService.new(domain, self)
    membership.leave(opts)
  end

  def follow_resources(resource_kind, resource_id_list = [])
    return if resource_id_list.blank?

    resources = build_resource_list(resource_kind, resource_id_list)
    resources.each do |resource|
      follow(resource)
    end
  end

  def build_resource_list(resource_kind, resource_id_list)
    return resource_dependent_all(resource_kind) if resource_id_list.include?('all')

    resource_kind.capitalize.constantize.where(id: resource_id_list)
  end

  def resource_dependent_all(resource_kind)
    return Topic.roots.all if resource_kind == 'Topic'

    resource_kind.capitalize.constantize.all
  end

  def member_or_power_or_guest_of?(resource)
    member_of?(resource) || power_of?(resource) || guest_of?(resource)
  end

  def admin_of?(resource)
    return false if resource.try(:tenant_name) == 'public'
    return true if resource.user == self

    has_role?(:admin, resource)
  end

  def member_of?(resource)
    return true if resource.try(:tenant_name) == 'public'
    return false unless resource.is_a?(Domain)

    domain_memberships.exists?(domain_id: resource.id, role: 'member', active: true)
  end

  def power_of?(resource)
    return true if resource.try(:tenant_name) == 'public'
    return false unless resource.is_a?(Domain)

    domain_memberships.exists?(domain_id: resource.id, role: 'power', active: true)
  end

  def guest_of?(resource)
    # return true if self.has_role?(:guest, resource) # -- UNUSED
    return false unless resource.is_a?(Domain)
    return false if member_of?(resource)

    domain_memberships.exists?(domain_id: resource.id, role: 'guest', active: true)
  end

  def group_memberships
    following_groups
  end

  def generate_notification_feed(frequency = 'daily')
    notifications.unsent_feed_since(frequency)
  end

  def merge_feed(feed)
    # Currently only merges tips assigned to topics
    feed_without_tips = feed.dup
    feed_without_tips.to_a.delete_if { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }

    merged_feed = []

    # Group tip notifications by topic
    feed.select { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }
      .group_by { |tip_feed_item| tip_feed_item.notifiable.follower.id }
      .each { |_key, group| merged_feed << group.first }

    merged_feed + feed_without_tips
  end

  def generate_tip_feed(options = {})
    return unless validate_email_sent_at(options[:days])

    days_before = Time.zone.now.advance(days: options[:days])

    feed = notifications
           .where('is_processed is false and created_at >= ?', days_before)
           .where(action: 'tip_feed')

    feed_ids = feed.ids
    return unless feed_ids.present?

    feed.update_all(is_processed: true)
    NotificationEmailWorker.perform_async(
      'tip_feed',
      notification_ids: feed_ids, email: email
    )

    update_sent_dates(options[:days])
  end

  def validate_email_sent_at(days = -365)
    return false unless user_profile
    today_date = Time.zone.now.to_date

    email_sent_at = user_profile.daily_sent_at.to_date  if user_profile.daily_sent_at.present? && days == -1
    email_sent_at = user_profile.weekly_sent_at.to_date if user_profile.weekly_sent_at.present? && days == -7

    !(email_sent_at.present? && today_date == email_sent_at)
  end

  def update_sent_dates(days)
    user_profile.update_attribute :daily_sent_at,  Time.zone.now if days == -1
    user_profile.update_attribute :weekly_sent_at, Time.zone.now if days == -7
  end

  def reset_password(new_password, new_password_confirmation)
    self.is_password_reset = true
    super
  end

  def replace_username
    self.username = [first_name.gsub(/\W/, ''), last_name.gsub(/\W/, '')].join('')

    self.username = username + id.to_s if User.where('username ILIKE ?', username).any?

    save
  end

  def generate_username
    self.username = SecureRandom.uuid
  end

  def viewable_tips(options = {})
    return viewable_tips_for_personal_tiphive(options) if current_domain.tenant_name == 'public'
    my_group_ids = following_groups.pluck(:id)

    tip_id_collection = (
      tips_followed_by(type: 'User', ids: [id]) +
      tips_followed_by(type: 'Group', ids: my_group_ids) +
      tips.pluck(:id)
    )

    unless guest_of?(current_domain)
      tip_id_collection += shared_tips_created_by(user_ids: user_followers.select(:id))
      tip_id_collection += public_tips_created_by(user_ids: public_creator_ids(my_group_ids))
    end

    tip_id_collection = tip_id_collection.uniq

    return options[:filter_resource].tip_followers.where(id: tip_id_collection) if options.key?(:filter_resource)

    context_join = 'LEFT JOIN context_tips ON context_tips.tip_id = tips.id'
    context_join += " AND context_tips.context_id = '#{options[:context].try(:id)}'"

    Tip.joins(context_join)
      .where('tips.id IN (?)', tip_id_collection)
      .order('context_tips.position')
      .order(created_at: 'DESC')
  end

  def viewable_tips_from(creator, context = nil)
    return [] if creator.blank?
    creator_tips = Tip.where(user_id: creator.id)
    tip_ids = []

    unless creator == self
      tip_ids = (
        tips_followed_by(type: 'User', ids: [id]) +
        tips_followed_by(type: 'Group', ids: following_groups.pluck(:id)) +
        (following?(creator) ? shared_tips_created_by(user_ids: [creator.id]) : [])
      )
    end

    context_join = 'LEFT JOIN context_tips ON context_tips.tip_id = tips.id'
    context_join += " AND context_tips.context_id = '#{context.try(:id)}'"

    tips = creator_tips.joins(context_join)
           .order('context_tips.position')
           .order(created_at: 'DESC')

    return tips if creator == self

    if member_of?(current_domain) || power_of?(current_domain)
      tips.where('tips.id IN (?) OR share_public = ?', tip_ids, true)
    else
      tips.where('tips.id IN (?)', tip_ids)
    end
  end

  def viewable_tips_for_personal_tiphive(_options = {})
    my_group_ids = following_groups.pluck(:id)

    tip_id_collection = (
      tips_followed_by(type: 'User', ids: [id]) +
      tips_followed_by(type: 'Group', ids: my_group_ids) +
      public_tips_created_by(user_ids: user_ids_following(group_ids: my_group_ids)) +
      public_tips_created_by(user_ids: following_users.select(:id)) +
      shared_tips_created_by(user_ids: user_followers.select(:id)) +
      tips.select(:id)
    ).uniq

    Tip.where(id: tip_id_collection).order(created_at: 'DESC')
  end

  # protected

  def password_confirmation_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  # private

  def tips_followed_by(type: nil, ids: nil)
    return [] if type.nil? || ids.blank?
    Follow.where(followable_type: 'Tip', follower_type: type, follower_id: ids).pluck(:followable_id)
  end

  def public_creator_ids(my_group_ids)
    user_ids_from_my_groups = user_ids_following(group_ids: my_group_ids)
    following_user_ids = following_users.pluck(:id)

    user_ids_from_my_groups + following_user_ids
  end

  def public_tips
    Tip.where(share_public: true).pluck(:id)
  end

  def public_tips_created_by(user_ids: nil)
    return [] if user_ids.blank?
    Tip.where(share_public: true, user_id: user_ids).pluck(:id)
  end

  def user_ids_following(group_ids: nil)
    return [] if group_ids.blank?
    Follow.where(followable_type: 'Group', followable_id: group_ids, follower_type: 'User').pluck(:follower_id)
  end

  def shared_tips_created_by(user_ids: nil)
    return [] if user_ids.blank?
    Tip.where(share_following: true, user_id: user_ids).pluck(:id)
  end

  def add_user_profile
    build_user_profile
  end

  def not_recovering_password
    password_confirmation.nil?
  end

  def updating_special_data
    changing_password = email_was.present? && email_changed?
    changing_encrypted_password = encrypted_password_was.present? && encrypted_password_changed?

    changing_password || (!is_password_reset && changing_encrypted_password)
  end

  def current_password_for_special_fields
    return true unless updating_special_data
    errors.add(:current_password, 'is invalid') unless validate_with_old_password?(current_password)
  end

  def validate_with_old_password?(password)
    Devise::Encryptor.compare(self.class, encrypted_password_was, password)
  end

  # Devise Trackable module calls this method after sign-in
  def update_tracked_fields!(request)
    params = request.filtered_parameters

    is_interact_with_tip = params['controller'] =~ /cards/ && %w(show create update destroy).include?(params['action'])
    is_sign_in = params['controller'] =~ /sessions|registrations/ && %w(create).include?(params['action'])

    should_update = is_sign_in || is_interact_with_tip ? true : false

    return unless should_update

    super(request)
  end
  
  def update_order(data)
    if data[:type] == 'label_orders'
      label_order_topic = self.user_topic_label_order.where(topic_id: data[:topic_id])
      if label_order_topic.present?
        label_order_topic.first.update(label_order_id: data[:label_order_id])
      else
        self.user_topic_label_order.create(topic_id: data[:topic_id], label_order_id: data[:label_order_id])
      end 
    elsif data[:type] == 'people_orders'
      people_order_topic = self.user_topic_people_order.where(topic_id: data[:topic_id])
      if people_order_topic.present?
        people_order_topic.first.update(people_order_id: data[:people_order_id])
      else
        self.user_topic_people_order.create(topic_id: data[:topic_id], people_order_id: data[:people_order_id])
      end
    else
      self.topic_orders = TopicOrder.where(id: data[:id]) 
    end  
  end  
end
