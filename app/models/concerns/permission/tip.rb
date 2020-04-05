module Permission
  module Tip
    extend ActiveSupport::Concern

    def masks(c_user)
      {
        is_admin: tip_admin?(c_user),
        is_owner: tip_owner?(c_user)
      }
    end

    def tip_admin?(c_user)
      c_user.has_role?(:admin, self)
    end

    def tip_owner?(c_user)
      user_id == c_user.id
    end

    def abilities(c_user)
      ability = Ability.new(c_user, current_domain)

      # Set the abilities according to domain
      abilities = {
        can_read:    ability.can?(:read, self),
        can_like:    ability.can?(:like, self),
        can_update:  ability.can?(:update, self),
        can_destroy: ability.can?(:destroy, self),
        can_comment: ability.can?(:comment, self)
      }

      actions = [:update, :destroy, :comment, :like]

      # Overrides based on topic permissions
      # if a topic is set to false for any permission, it overrides the domain ability
      topics.each do |topic|
        break if actions.empty?
        ability = Ability.new(c_user, current_domain, topic)

        actions.each do |action|
          unless ability.can?(action, self)
            abilities["can_#{action}".to_sym] = false
            actions -= [action]
          end
        end
      end

      { self: abilities }
    end
  end
end
