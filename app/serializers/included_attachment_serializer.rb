class IncludedAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  set_type :attachments

  attributes :name, :type

  attribute :file_url do |object|
    object.file.try :url
  end

  # attribute :file_content_type do |object|
  #   ['Document', 'Image'].include?(object.type) ? object.file_content_type : 'link'
  # end

end
