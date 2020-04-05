class DomainSimpleSerializer < ActiveModel::Serializer
  attributes :name,
             :tenant_name,
             :logo,
             :join_type,
             :email_domains,
             :allow_invitation_request,
             :user

  def logo
    object.logo.small.url
  end
end
