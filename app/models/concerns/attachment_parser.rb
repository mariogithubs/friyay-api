module AttachmentParser
  extend ActiveSupport::Concern

  def process_attachments_as_json
    attachment_types = %w(Image Document SlackLink)
    faux_attachment_types = %w(TipLink)

    attachment_list = attachments.where(type: attachment_types).group_by(&:type)

    faux_attachment_types.each do |kind|
      attachment_list[kind] = send(kind.underscore.pluralize).flatten
    end

    return if attachment_list.blank?

    attachment_list.each do |a_type, a_list|
      builder = "build_#{a_type.underscore}_json"

      a_list.map! do |attachment|
        send(builder, attachment)
      end
    end

    attachment_list.keys.each { |key| attachment_list[key.underscore.pluralize] = attachment_list.delete(key) }

    update_attribute(:attachments_json, attachment_list.as_json)
  end

  def process_image_as_attachment_json(image)
    delete_current_attachment_for(image)
    attachments_json['images'] = [] if attachments_json['images'].nil?  
    attachments_json['images'] << build_image_json(image)

    save
  end

  def delete_current_attachment_for(attachment)
    kind_plural = attachment.class.name.downcase.pluralize
    return if attachments_json[kind_plural].blank?

    attachments_json[kind_plural].delete_if { |kind| kind['id'] == attachment.id }
  end

  private

  def build_image_json(image)
    {
      id: image.id,
      name: image.name,
      file_url: image.file_url,
      file_small_url: image.file_url,
      file_size: image.file_size,
      file_content_type: image.file_content_type,
      file_processing: image.file_processing,
      original_url: image.original_url
    }
  end

  def build_document_json(document)
    {
      id: document.id,
      name: document.name,
      file_url: document.file_url,
      file_size: document.file_size,
      file_content_type: document.file_content_type
    }
  end

  def build_tip_link_json(tiplink)
    {
      title: tiplink.title,
      description: tiplink.description,
      avatar_url: tiplink.avatar_url,
      avatar_processing: tiplink.avatar_processing,
      url: tiplink.url,
      user: tiplink.user.name,
      processed: tiplink.processed
    }
  end

  def build_slack_link_json(slacklink)
    {
      id: slacklink.id,
      file_url: slacklink.file,
      messages: slacklink.messages
    }
  end
end
