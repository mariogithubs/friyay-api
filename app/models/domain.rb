# == Schema Information
#
# Table name: public.domains
#
#  id                          :integer          not null, primary key
#  user_id                     :integer          not null, indexed
#  name                        :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  tenant_name                 :string           not null, indexed
#  logo                        :string
#  logo_tmp                    :string
#  logo_processing             :boolean
#  background_image            :string
#  background_image_tmp        :string
#  background_image_processing :boolean
#  is_public                   :boolean          default(FALSE)
#  join_type                   :integer          default(0), not null
#  email_domains               :string
#  allow_invitation_request    :boolean          default(FALSE), not null
#  sso_enabled                 :boolean          default(FALSE)
#  idp_entity_id               :string
#  idp_sso_target_url          :string
#  idp_slo_target_url          :string
#  idp_cert                    :text
#  issuer                      :string
#  default_view_id             :string
#  is_disabled                 :boolean          default(FALSE)
#  is_deleted                  :boolean          default(FALSE)
#  stripe_customer_id          :string
#  stripe_card_id              :string
#  color                       :string
#

# rubocop:disable Style/RedundantReturn
class Domain < ActiveRecord::Base
  include Adminify
  include Filterable
  include Utils::Domain

  resourcify

  enum join_type: {
    invitation_required: 0,
    # 1 is available if we need to add another join_type
    open: 2
  }

  serialize :email_domains, Array

  has_many :domain_memberships, dependent: :destroy
  has_many :domain_members, through: :domain_memberships, foreign_key: :user_id
  has_many :users_roles, through: :roles, source: :roles_users
  has_many :slack_teams

  has_one :domain_permission, as: :permissible, dependent: :destroy
  has_one :contact_information
  has_one :subscription

  accepts_nested_attributes_for :domain_permission, allow_destroy: true

  belongs_to :user

  before_validation :create_tenant_name
  after_create :create_tenant, :creator_follow_domain, :create_default_labels, :create_default_views

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :tenant_name, uniqueness: true
  validates :tenant_name, domain_not_reserved: true
  # we don't have a mechanism to change postgres tenant yet
  validate :tenant_name_can_not_be_updated, on: :update

  validates :name, format:
                    {
                      with: /\A(?:[A-Z0-9\-',\. ])+\z/i,
                      message: 'Invalid name. Please only use names with letters (A-Z) and numbers (0-9).'
                    }

  mount_uploader :logo, ImageUploader
  mount_uploader :background_image, BackgroundImageUploader

  process_in_background :logo
  process_in_background :background_image

  store_in_background   :logo
  store_in_background   :background_image

  scope :with_logo, -> { where("logo IS NOT NULL AND logo != ''") }
  scope :with_background_image, -> { where("background_image IS NOT NULL AND background_image != ''") }
  scope :enabled, -> { where(is_deleted: false, is_disabled: false) } 
  @@topic_map = {}

  def title
    name
  end

  def invite_url
    ''
  end

  def host_url
    return ENV['TIPHIVE_HOST'] if tenant_name == 'public'

    [tenant_name, ENV['TIPHIVE_HOST_NAME']].join('.')
  end

  def users
    dm_ids = DomainMembership.where(domain_id: id).pluck(:user_id)

    return User.where(id: dm_ids) unless public_domain?

    User.all
  end
  alias_method :members, :users

  def guests
    return [] if public_domain?

    domain_memberships.where(role: 'guest').map(&:user)
  end

  def creator?(user_or_user_id)
    user_id == user_or_user_id || user_id == user_or_user_id.id
  end

  def logo_thumbnail_url
    logo.square.url
  end

  def background_image_thumbnail_url
    background_image.square.url
  end

  def public_access?
    public_domain_ids = []
    public_domain_ids << ENV['SUPPORT_DOMAIN_ID'].to_i if ENV['SUPPORT_DOMAIN_ID'].present?
    public_domain_ids.include?(id)
  end

  def public_domain?
    new_record?
  end

  def private_domain?
    id.present?
  end

  def add_user(new_member)
    join_result, message = send("#{join_type}_join", new_member)
    new_member.join(self) if join_result == true

    return join_result, message
  end

  def add_guest(guest_user)
    guest_user.join(self, as: 'guest')
    guest_user.add_role(:guest, self)
  end

  def email_acceptable?(email)
    user_email_domain = email.split('@').last

    email_domains.include?(user_email_domain)
  end

  # Saves card and customer tokens received from stripe
  def update_stripe_card_and_customer(card_token, customer_token)
    self.update_attribute(:stripe_card_id, card_token) unless card_token.nil?
    self.update_attribute(:stripe_customer_id, customer_token) unless customer_token.nil?
  end
  
  class << self
    def reprocess_images!
      with_logo.each do |instance|
        begin
          instance.process_logo_upload = true # only if you use carrierwave_backgrounder
          instance.logo.cache_stored_file!
          instance.logo.retrieve_from_cache!(instance.logo.cache_name)
          instance.logo.recreate_versions!
          instance.save!
        rescue => e
          Rails.logger.info("\n ERROR: DomainLogo: #{instance.id} -> #{e} \n")
        end
      end

      with_background_image.each do |instance|
        begin
          instance.process_background_image_upload = true # only if you use carrierwave_backgrounder
          instance.background_image.cache_stored_file!
          instance.background_image.retrieve_from_cache!(instance.background_image.cache_name)
          instance.background_image.recreate_versions!
          instance.save!
        rescue => e
          Rails.logger.info("\n ERROR: DomainBackground: #{instance.id} -> #{e} \n")
        end
      end
    end
  end # class

  def permission
    d_permissions = domain_permission.try(:access_hash) || {}
    ActivityPermission::DEFAULT_ACCESS_HASH.merge(d_permissions.deep_symbolize_keys)
  end

  def add_slack_team(data, user)
    return [nil, 'Invalid information'] if data[:team_id].blank?

    slack_team = slack_teams.find_by(team_id: data[:team_id], access_token: data[:access_token])
    slack_team ||= slack_teams.build(team_id: data[:team_id], access_token: data[:access_token])
    slack_team.bot = data[:bot]
    slack_team.scope = data[:scope]
    slack_team.team_name = data[:team_name]
    slack_team.incoming_webhook = data[:incoming_webhook]
    slack_team.user_ids << user.id

    slack_team.save ? [slack_team, 'Success'] : [nil, slack_team.errors.full_messages]
  end

  def archive(params)
    new_domain = Domain.find_by(id: params[:data][:tenant_name])
    old_domain = Domain.find_by(tenant_name: Apartment::Tenant.current)

    if new_domain.present? 
      move_all_to_domain(old_domain.tenant_name, new_domain.tenant_name)
      move_all_tips(@@topic_map, old_domain.tenant_name, new_domain.tenant_name)
    else
      #archive all topics and tips
      Topic.update_all(is_disabled: true)
      Tip.update_all(is_disabled: true)
    end
    self.update_attributes(is_disabled: true)
  end

  def delete(params)
    new_domain = Domain.find_by(id: params.try(:[], 'data').try(:[], 'tenant_name'))
    old_domain = Domain.find_by(tenant_name: Apartment::Tenant.current)
    if new_domain.present?
      move_all_to_domain(old_domain.tenant_name, new_domain.tenant_name)
      move_all_tips(@@topic_map, old_domain.tenant_name, new_domain.tenant_name)
    else
      #delete all topics and tips
      Topic.update_all(is_deleted: true)
      Tip.update_all(is_deleted: true)
    end
    self.update_attributes(is_deleted: true)
  end

  def move_all_to_domain(old_domain, new_domain)
    topics = []
    Apartment::Tenant.switch old_domain do
      topics = Topic.all
    end
    topics.each do |topic|
      if topic.is_root?
        move_to_domain(topic, old_domain, new_domain)
      end
    end
  end

  def move_to_domain(old_topic, old_domain, new_domain, parent_id = nil)
    new_topic = old_topic.dup.attributes.merge({'ancestry' => nil, 'old_subtopic_id' => nil})

    newly_created_topic = nil
    Apartment::Tenant.switch new_domain do
      newly_created_topic = Topic.create(new_topic.merge(parent_id: parent_id))
      print '.'
    end

    @@topic_map[old_topic.id] = newly_created_topic.id

    return unless old_topic.children?

    old_topic.children.each do |child|
      move_to_domain(child, old_domain, new_domain, newly_created_topic.id)
    end
  end # Move to domain 

  def move_all_tips(topic_map, old_domain, new_domain)
    Apartment::Tenant.switch old_domain do
      follows = Follow.includes(:follower).where(
        followable_type: 'Topic',
        followable_id: topic_map.keys,
        follower_type: 'Tip'
      )

      tips = follows.map(&:follower)

      tips = tips.uniq.compact #.select{ |tip| tip[:user_id] == user.id }
      tips.each_with_index do |tip, index|
        tip_follows = follows.select{ |f| f[:follower_id] == tip.id }
        tip_following_topic_ids = tip_follows.map{ |cf| topic_map[cf.followable_id] }

        move_tip_to_domain(tip, tip_following_topic_ids, old_domain, new_domain)
      end
    end
  end

  def move_tip_to_domain(old_tip, following_topic_ids, old_domain, new_domain)
    new_tip = old_tip.dup

    attachment_map = []
    old_tip.attachments.each do |attachment|
      attachment_map << {
        attachment: attachment.dup,
        old_attachment_file_url: attachment.type == 'Link' ? '' : attachment.file_url
      }
    end

    Apartment::Tenant.switch new_domain do
      newly_created_tip = Tip.create(new_tip.attributes)

      following_topic_ids.each do |follow_id|
        newly_created_tip.follow(Topic.find(follow_id)) rescue next
        print 'f'
      end

      attachment_map.each do |attachment_data|
        new_attachment = attachment_data[:attachment]

        next if new_attachment.blank?

        new_attachment.attachable_id = newly_created_tip.id
        # BUG: This should work, but we're getting Forbidden errors
        unless new_attachment.type == 'Link'
          new_attachment.remote_file_url = attachment_data[:old_attachment_file_url]
        end

        new_attachment.save
      end
    end

    s3 = S3CopyObject.new(old_domain, new_domain)
    s3.copy_images(old_tip.id)
    s3.copy_documents(old_tip.id)
  end 

  private

  def create_tenant
    Apartment::Tenant.create(tenant_name)
  end

  def create_tenant_name
    self.tenant_name = process_tenant_name
  end

  def process_tenant_name
    return tenant_name.parameterize if tenant_name
    return '' if name.blank?
    return name.parameterize if tenant_name.blank?
  end

  def tenant_name_can_not_be_updated
    errors.add(:tenant_name, "can't be updated") if tenant_name_changed?
  end

  def creator_follow_domain
    # return true if Apartment::Tenant.current == 'public'

    domain_memberships.find_or_create_by(user_id: user.id)
  end

  def create_default_labels
    Apartment::Tenant.switch tenant_name do
      Label.create_default_labels
    end
  end

  def create_default_views
    Apartment::Tenant.switch tenant_name do
      View.create_default_views
    end
  end

  def invitation_required_join(new_member)
    return true if email_acceptable?(new_member.email)
    return false, 'An invitation is required to join this domain.'
  end

  def open_join(new_member)
    domain_memberships.find_or_create_by(user_id: new_member.id)
    return true, ''
  end

  def email_approved?(new_member)
    user_email_domain = new_member.email.split('@').last

    email_domains.include?(user_email_domain)
  end
end
# rubocop:enable Style/RedundantReturn
