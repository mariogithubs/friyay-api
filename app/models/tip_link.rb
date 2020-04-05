# == Schema Information
#
# Table name: tip_links
#
#  id                :integer          not null, primary key
#  url               :string
#  tip_id            :integer
#  user_id           :integer
#  title             :string
#  description       :text
#  avatar            :string
#  avatar_tmp        :string
#  avatar_processing :boolean
#  processed         :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class TipLink < ActiveRecord::Base
  validates :url, presence: true

  belongs_to :tip, inverse_of: :tip_links
  belongs_to :user, inverse_of: :tip_links

  mount_uploader :avatar, ImageUploader
  process_in_background :avatar
  store_in_background   :avatar

  after_create :enqueue_thumbnailing

  def thumbnail_url
    avatar.square.url
  end

  def enqueue_thumbnailing
    ThumbnailerWorker.perform_in(30.seconds, id)
  end

  def thumbnail_it
    begin
      page = LinkThumbnailer.generate(url)
    rescue StandardError => e
      logger.error e.message
    end

    if page
      thumbnail = page.images.first.src.to_s if page.images.first
      self.title = page.title
      self.description = page.description
      # Teefan: don't store redirected URL so that we know if url is existed
      # self.url = page.url.to_s
      self.remote_avatar_url = thumbnail if thumbnail.present?
    end

    self.title = url if title.blank?
    self.processed = true

    save!
  end

  def self.add_and_remove(tip, old_links, new_links)
    remove(tip, old_links - new_links)
    add(tip, new_links)
  end

  def self.remove(tip, urls)
    urls.each do |url|
      tip_link = tip.tip_links.find_by(url: url)
      tip_link.destroy if tip_link.present?
    end
  end

  def self.add(tip, urls)
    urls.each do |url|
      tip_link = tip.tip_links.find_by(url: url)
      tip.tip_links.create(url: url, user_id: tip.user_id) unless tip_link
    end
  end
end
