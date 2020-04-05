module ActsAsFlaggable
  extend ActiveSupport::Concern

  included do
    has_many :flags, as: :flaggable, dependent: :destroy
  end

  def flag(user, reason)
    flag_params = {
      flaggable_type: self.class.name,
      flaggable_id: id,
      flagger_id: user.id,
      flagger_type: user.class.name,
      reason: reason
    }

    Flag.create(flag_params)
  end
end
