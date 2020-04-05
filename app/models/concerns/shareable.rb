module Shareable
  extend ActiveSupport::Concern

  included do
    has_many :share_settings, as: :shareable_object, dependent: :destroy
  end

  def find_or_create_share_settings_for(share_with_relationship)
    # TODO: move share with overrides FROM connectable to here
    return if override?(share_with_relationship) # We handle share_with_override in Connectable

    share_settings_params = {
      sharing_object_id: share_with_relationship.id,
      sharing_object_type: share_with_relationship.class.name,
      user_id: user_id
    }
    # TODO: need to find a way not to rely on self.user_id
    # Just in case we start allowing someone other than the owner to set share settings
    share_settings.find_or_create_by(share_settings_params)
  end

  def override?(share_with_relationship)
    return true if Connectable::OVERRIDE_TYPES.include?(share_with_relationship.id)

    false
  end
end
