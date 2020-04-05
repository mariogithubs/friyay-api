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

class Location < Attachment
  validates :file,
            format: { with: URI.regexp, message: '%{value} is not a valid url' }, if: proc { |a| a.file.present? }

  validates :file, uniqueness: { scope: [:attachable_id, :attachable_type] }

  def self.add_and_remove(tip, old_links, new_links)
    add(tip, new_links)
    remove(tip, old_links - new_links)
  end

  def self.add(tip, urls)
    urls.each do |url|
      attachment = tip.attachments.find_by(file: url)
      urls.each { |url| tip.attachments.create(file: url, type: 'Location') } unless attachment.present?
    end
  end

  def self.remove(tip, urls)
    urls.each do |url|
      attachment = tip.attachments.find_by_file_and_type(url, 'Location')
      attachment.destroy if attachment.present?
    end
  end
end
