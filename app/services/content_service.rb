class ContentService
  CONTENT_TYPES = %w(
    tips
    topics
    groups
    comments
    labels
    tip_links
    attachments
  )

  def self.reassign(domain, from_user_id, to_user_id)
    return if [from_user_id, to_user_id].any?(&:blank?)

    Apartment::Tenant.switch domain.tenant_name do
      CONTENT_TYPES.each do |content_type|
        resource = content_type.classify.constantize

        resources = resource.where(user_id: from_user_id)

        resources.update_all(user_id: to_user_id)
      end
    end
  end
end
