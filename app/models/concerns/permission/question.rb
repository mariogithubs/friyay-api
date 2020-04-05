module Permission
  module Question
    extend ActiveSupport::Concern

    def masks(c_user)
      {
        is_admin: question_admin?(c_user),
        is_owner: question_owner?(c_user)
      }
    end

    def question_admin?(c_user)
      c_user.has_role? :admin, self
    end

    def question_owner?(c_user)
      user == c_user
    end

    def abilities(c_user)
      ability = Ability.new(c_user, current_domain)

      abilities = {
        can_read:    ability.can?(:read, self),
        can_like:    ability.can?(:like, self),
        can_update:  ability.can?(:update, self),
        can_destroy: ability.can?(:destroy, self),
        can_answer:  ability.can?(:answer, self)
      }

      actions = [:update, :destroy, :answer, :like]

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
