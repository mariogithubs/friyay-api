# == Schema Information
#
# Table name: topic_preferences
#
#  id                          :integer          not null, primary key
#  topic_id                    :integer          not null, indexed, indexed => [user_id]
#  user_id                     :integer          not null, indexed => [topic_id], indexed
#  background_color_index      :integer          default(1), not null
#  background_image            :string           default(""), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  background_image_tmp        :string
#  background_image_processing :boolean
#  share_public                :boolean          default(TRUE)
#  share_following             :boolean          default(FALSE)
#  follow_scope                :integer          default(2)
#  link_option                 :text
#  link_password               :string
#

class TopicPreference < ActiveRecord::Base
  include TipFinder
  include Connectable::Model

  belongs_to :topic
  belongs_to :user

  acts_as_followable

  before_validation :generate_background_color

  validates :topic_id, :user_id, presence: true
  validates :background_color_index, presence: true

  mount_uploader :background_image, BackgroundImageUploader

  process_in_background :background_image
  store_in_background   :background_image

  scope :with_background_image, -> { where("background_image IS NOT NULL AND background_image != ''") }

  enum follow_scope: {
    follow_no_users: 0,
    follow_select_users: 1,
    follow_all_users: 2,
    block_users: 3
  }

  def self.preferences(user_id = nil)
    find_by(user_id: user_id) || first
  end

  def background_image_thumbnail_url
    background_image.square.url
  end

  def private?
    return false if share_public == true
    return false if share_following == true
    return false if topic.share_settings.count > 0

    true
  end

  class << self
    def reprocess_images!
      with_background_image.each do |instance|
        begin
          instance.process_background_image_upload = true # only if you use carrierwave_backgrounder
          instance.background_image.cache_stored_file!
          instance.background_image.retrieve_from_cache!(instance.background_image.cache_name)
          instance.background_image.recreate_versions!
          instance.save!
        rescue => e
          Rails.logger.info("ERROR: TopicPreference: #{instance.id} -> #{e}")
        end
      end
    end

    def for_user(user)
      # THIS IS A SCOPE USUALLY BEGINNING WITH topic.topic_preferences
      # ALREADY SCOPED TO TOPIC
      topic_preference = find_by(user_id: user.id)
      return topic_preference if topic_preference.present?

      topic_preference = create(
        user_id: user.id
      )

      topic_preference
    end
  end # class

  private

  def generate_background_color
    return if background_color_index.present?
    self.background_color_index = rand(1..7)
  end
end
