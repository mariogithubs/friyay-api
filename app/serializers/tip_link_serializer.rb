class TipLinkSerializer < ActiveModel::Serializer
  attributes :title, :description, :avatar_url, :avatar_processing, :url, :user, :processed
end
