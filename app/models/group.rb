# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key, indexed
#  user_id                     :integer          not null, indexed
#  title                       :string           indexed
#  description                 :text
#  join_type                   :string
#  group_type                  :string
#  color_index                 :integer
#  background_image            :string
#  image_top                   :integer
#  image_left                  :integer
#  address                     :string
#  location                    :string
#  zip                         :string
#  latitude                    :float
#  longitude                   :float
#  avatar                      :string
#  admin_ids                   :string
#  is_auto_accept              :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  avatar_tmp                  :string
#  avatar_processing           :boolean
#  background_image_tmp        :string
#  background_image_processing :boolean
#

class Group < ActiveRecord::Base
  include AttachmentUrl
  include Slugger
  include Connectable::Model

  mount_uploader :avatar, ImageUploader
  mount_uploader :background_image, BackgroundImageUploader

  process_in_background :avatar
  process_in_background :background_image

  store_in_background   :avatar
  store_in_background   :background_image

  belongs_to :user
  has_many :invitations, as: :invitable

  has_many :tips, through: :tip_assignments
  has_many :tip_assignments, as: :assignment

  acts_as_followable
  acts_as_follower

  validates :user, presence: true
  validates :title, presence: true

  before_validation :generate_color
  after_create :share_with_creator

  scope :with_avatar, -> { where("avatar IS NOT NULL AND avatar != ''") }
  scope :with_background_image, -> { where("background_image IS NOT NULL AND background_image != ''") }

  searchable do
    text :title, :description

    string :name do
      title.downcase
    end

    string :kind do
      self.class.name
    end

    string :tenant_name do
      Apartment::Tenant.current
    end
  end

  def name
    title.downcase
  end

  def add_member(new_member)
    result = { success: true }

    case join_type
    when 'invite'
      result = { success: false, message: 'This group requires an invitation.' }
    when 'domain'
      # TODO: Check user.email_domain against list of domains
      # current tiphive uses taggings? maybe we use serialized field
    when 'location'
      # TODO: Check user.email_domain against list of zipcodes
      # current tiphive uses taggings? maybe we use serialized field
    else
      new_member.follow(self)
    end

    result
  end

  def invite(new_member)
    invitations.create(user_id: user_id, email: new_member.email, invitation_type: :group)
  end

  def invite_url
    "/groups/#{id}"
  end

  def members
    # TODO: write test
    user_followers
  end

  def topics
    (following_topics.without_root + Topic.roots_for(subtopics)).uniq
  end

  def subtopics
    following_topics.with_root
  end

  class << self
    def reprocess_images!
      with_avatar.each do |instance|
        begin
          instance.process_avatar_upload = true # only if you use carrierwave_backgrounder
          instance.avatar.cache_stored_file!
          instance.avatar.retrieve_from_cache!(instance.avatar.cache_name)
          instance.avatar.recreate_versions!
          instance.save!
        rescue => e
          Rails.logger.info("ERROR: GroupAvatar: #{instance.id} -> #{e}\n")
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
          Rails.logger.info("ERROR: GroupBackgroundImage: #{instance.id} -> #{e}\n")
        end
      end
    end
  end

  private

  def generate_color
    self.color_index = 8
  end
end
