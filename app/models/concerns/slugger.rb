module Slugger
  extend ActiveSupport::Concern

  def to_param
    return id.to_s if title.blank?
    "#{id}-#{title.parameterize}"
  end
  alias_method :slug, :to_param
end
