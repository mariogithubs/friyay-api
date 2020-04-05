class AttachmentSerializer
  include FastJsonapi::ObjectSerializer

  set_type :attachments

  attributes :name, :file_content_type

  attribute :file_url do |object|
    object.file.try :url
  end

  attribute :file_size do |object|
    object.file.try :size
  end

  belongs_to :attachable, polymorphic: true

  attribute :file_content_type do |object|
    ['Document', 'Image'].include?(object.type) ? object.file_content_type : 'link'
  end

  attribute :thumbnail_url do |object|
    object.try :thumbnail_url
  end

end
