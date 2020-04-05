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

class Attachment < ActiveRecord::Base
  belongs_to :user
  belongs_to :attachable, polymorphic: true

  validates :file, presence: true, on: :create
  validates :type, presence: true

  delegate :url,          to: :file, prefix: true
  delegate :size,         to: :file, prefix: true
  delegate :content_type, to: :file, prefix: true

  # store external uploaded file mime type
  attr_accessor :mime_type

  # Auto generate attachment name
  def name
    "Attachment ##{id}"
  end

  def self.detect_attachment_type(content_type)
    attachment_type = 'Document'
    attachment_type = 'Image' if %w(image/jpeg image/png image/gif).include?(content_type)
    attachment_type
  end
end
