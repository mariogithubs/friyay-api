# == Schema Information
#
# Table name: public.user_profiles
#
#  id                          :integer          not null, primary key
#  user_id                     :integer          indexed
#  avatar                      :string
#  avatar_tmp                  :string
#  avatar_processing           :boolean
#  background_image            :string
#  background_image_processing :boolean
#  background_image_tmp        :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  color_index                 :integer          default(5)
#  daily_sent_at               :datetime
#  weekly_sent_at              :datetime
#  description                 :text
#  follow_all_members          :boolean          default(TRUE)
#  follow_all_hives            :boolean          default(TRUE)
#  resource_capacity           :integer
#

class UserProfile < ActiveRecord::Base
  EMAIL_NOTIFICATION_SETTINGS = [
    :someone_likes_tip,
    :someone_likes_question,
    :someone_add_tip_to_topic,
    :someone_shared_topic_with_me,
    :someone_shared_tip_with_me,
    :someone_shared_question_with_me,
    :someone_comments_on_tip,
    :someone_added_to_group,
    :someone_added_to_domain,
    :someone_joins_domain,
    :someone_adds_tip,
    :someone_adds_topic,
    :someone_mentioned_on_comment,
    :someone_followed_you,
    :someone_commented_on_tip_user_commented,
    :someone_assigned_tip
  ]

  COUNTERS = [
    :total_tips,
    :total_comments,
    :total_likes,
    :total_likes_received,
    :total_user_followers,
    :total_following_topics,
    :total_views
  ]

  UI_SETTINGS = {
    all_topics_view: 'TILE',
    my_topics_view: [],
    tips_view: nil,
    hex_panel: true,
    left_menu_open: true,
    left_menu_people_filter: 'all',
    left_menu_topics_filter: 'all',
    left_menu_people_panel: true,
    minimize_dock: [],
    tour_introduction_finished: false,
    unprioritizedPanelClosed: {},
    subtopics_panel_view: 'TILE',
    cards_hidden_in_workspace: false,
    topics_panel_visible: true,
  }

  include AttachmentUrl
  include Join::UserProfile

  belongs_to :user, inverse_of: :user_profile

  mount_uploader :avatar, ImageUploader
  mount_uploader :background_image, BackgroundImageUploader

  process_in_background :avatar
  process_in_background :background_image

  # store_in_background   :avatar
  # store_in_background   :background_image

  scope :with_avatar, -> { where("avatar IS NOT NULL AND avatar != ''") }
  scope :with_background_image, -> { where("background_image IS NOT NULL AND background_image != ''") }

  has_settings do |s|
    s.key :email_notifications,
          defaults: {
            someone_likes_tip: :never,
            someone_likes_question: :daily,
            someone_add_tip_to_topic: :never,
            someone_shared_topic_with_me: :never,
            someone_shared_tip_with_me: :never,
            someone_shared_question_with_me: :always,
            someone_comments_on_tip: :always,
            someone_added_to_group: :always,
            someone_added_to_domain: :never,
            someone_joins_domain: :daily,
            someone_adds_tip: :daily,
            someone_adds_topic: :daily,
            someone_mentioned_on_comment: :always,
            someone_followed_you: :never,
            someone_commented_on_tip_user_commented: :always,
            someone_assigned_tip: :always
          }
    s.key :domain_follows, defaults: { follow_all_topics: false, follow_all_domain_members: false }
    s.key :counters, defaults: COUNTERS.inject({}) { |hash, (k)| hash.merge(k => 0) }
    s.key :ui_settings, defaults: UI_SETTINGS
  end

  accepts_nested_attributes_for :user

  attr_accessor :email_notifications, :follow_all_topics, :follow_all_domain_members

  def notification_settings
    EMAIL_NOTIFICATION_SETTINGS.map { |k| { key: k, value: settings(:email_notifications).send(k) } }
  end

  def counters
    COUNTERS.inject({}) { |hash, (k)| hash.merge(k => settings(:counters).send(k)) }
  end

  def ui_settings
    UI_SETTINGS.keys.map { |k| { key: k, value: settings(:ui_settings).send(k) } }
  end

  def follow_all_topics!(val = true)
    # TODO: Refactor, should be set_follow_all_topics!(val = true)
    # Don't change if these are true
    return true if val == follow_all_topics
    return true if Apartment::Tenant.current == 'public'

    settings(:domain_follows).update_attributes! follow_all_topics: val
  end

  def follow_all_domain_members!(val = true)
    # Don't change if these are true
    return true if val == follow_all_domain_members
    return true if Apartment::Tenant.current == 'public'

    settings(:domain_follows).update_attributes! follow_all_domain_members: val
  end

  def follow_all_topics
    settings(:domain_follows).follow_all_topics
  end

  def follow_all_domain_members
    settings(:domain_follows).follow_all_domain_members
  end

  def increment_counter(counter_key, qty = 1)
    Rails.logger.info("\n\n***** Incrementing: #{counter_key} for #{user.email} by #{qty} ******\n\n")
    new_value = settings(:counters).send(counter_key).try(:+, qty) || qty
    settings(:counters).update_attributes!(counter_key => new_value)
  end

  def decrement_counter(counter_key, qty = 1)
    Rails.logger.info("\n\n***** Decrementing: #{counter_key} for #{user.email} by #{qty} ******\n\n")
    return unless settings(:counters).value.key?(counter_key)
    return if settings(:counters).send(counter_key) == 0
    new_value = settings(:counters).send(counter_key) - qty
    new_value = new_value < 0 ? 0 : new_value
    settings(:counters).update_attributes!(counter_key => new_value)
  end

  def reset_counters
    settings(:counters).update_attributes!(
      total_tips: user.tips.size,
      total_comments: user.comments.size,
      total_likes: user.votes.where(vote_scope: 'like').size,
      total_likes_received: user.tips.map(&:cached_scoped_like_votes_up).sum,
      total_user_followers: user.user_followers.count,
      total_following_topics: user.following_topics_count,
      total_views: user.assigned_views.size
    )
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
          Rails.logger.info("ERROR: UserAvatar: #{instance.id} -> #{e}")
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
          Rails.logger.info("ERROR: UserBackground: #{instance.id} -> #{e}")
        end
      end # background_image
    end # reprocess_image
  end # class
end
