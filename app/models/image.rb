# == Schema Information
#
# Table name: attachments
#
#  id                 :integer          not null, primary key
#  file               :string
#  type               :string           indexed
#  attachable_type    :string           indexed => [attachable_id], indexed
#  attachable_id      :integer          indexed => [attachable_type], indexed
#  file_processing    :boolean
#  file_tmp           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer          indexed
#  zencoder_output_id :string
#  zencoder_processed :boolean          default(FALSE)
#  old_resource_id    :integer
#  original_url       :string
#  messages           :text
#

class Image < Attachment
  mount_uploader :file, ImageUploader
  process_in_background :file
  store_in_background   :file

  scope :with_file, -> { where("file IS NOT NULL AND file != ''") }

  def thumbnail_url
    file.square.url
  end

  class << self
    def reprocess_images!
      with_file.each do |instance|
        begin
          instance.process_file_upload = true # only if you use carrierwave_backgrounder
          instance.file.cache_stored_file!
          instance.file.retrieve_from_cache!(instance.file.cache_name)
          instance.file.recreate_versions!
          instance.save!
        rescue => e
          Rails.logger.info("ERROR: Image: #{instance.id} -> #{e}")
        end
      end
    end
  end # class

  def self.add_and_remove(tip, old_links, new_links)
    remove(tip, old_links - new_links)
    add(tip, new_links)
  end

  def self.remove(tip, urls)
    urls.each do |url|
      attachment = tip.attachments.find_by_original_url_and_type(url, 'Image')
      attachment.destroy if attachment.present?
    end
  end

  def self.add(tip, urls)
    urls.each do |url|
      attachment = tip.attachments.find_by_original_url_and_type(url, 'Image')
      tip.attachments.create(original_url: url, remote_file_url: url, type: 'Image') unless attachment.present?
    end
  end
end
