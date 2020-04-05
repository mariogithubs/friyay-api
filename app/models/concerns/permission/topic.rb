module Permission
  module Topic
    extend ActiveSupport::Concern

    def masks(c_user)
      {
        is_admin: topic_admin?(c_user),
        is_owner: topic_owner?(c_user)
      }
    end

    def domain_admin?(c_user)
      c_user.has_role? :admin, current_domain
    end

    def topic_admin?(c_user)
      c_user.has_role? :admin, self
    end

    def topic_owner?(c_user)
      user == c_user
    end

    def domain_owner?(c_user)
      current_domain.user.present? && current_domain.user == c_user
    end

    def abilities(c_user)
      ability = Ability.new(c_user, current_domain, self)
      {
        self: {
          can_edit: ability.can?(:update, self),
          can_delete: ability.can?(:destroy, self)
        },
        tips: {
          can_create: ability.can?(:create, ::Tip)
        },
        questions: {
          can_create: ability.can?(:create, ::Question)
        }
      }
    end

    def can_create?(resource, c_user)
      return abilities(c_user)[:tips][:can_create] if resource.is_a?(Tip)
      return abilities(c_user)[:questions][:can_create] if resource.is_a?(Question)
    end
  end
end
