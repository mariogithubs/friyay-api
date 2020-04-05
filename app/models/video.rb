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

class Video < Attachment
  mount_uploader :file, VideoUploader
  process_in_background :file
  store_in_background   :file
end
