module Permission
  extend ActiveSupport::Concern

  def roles(c_user)
    {
      is_admin: domain_admin?(c_user),
      is_owner: domain_owner?(c_user),
      is_topic_admin: topic_admin?(c_user),
      is_topic_owner: topic_owner?(c_user)
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
    topic_abilities(c_user)
  end

  def topic_abilities(c_user)
    ability = Ability.new(c_user, current_domain, self)

    {
      topic: {
        can_edit: ability.can?(:update, self),
        can_delete: ability.can?(:destroy, self)
      },
      tips: {
        can_create: ability.can?(:create, Tip)
      },
      questions: {
        can_create: ability.can?(:create, Question)
      }
    }
  end

  # def question_abilities(ability, question)
  #   # ability = Ability.new(c_user, current_domain, self)

  #   abilities = {}

  #   [:read, :update, :destroy, :answer, :like].each do |action|
  #     abilities["can_#{action}".to_sym] = ability.can?(action, question)
  #   end

  #   abilities
  # end

  def current_domain
    Domain.find_by(tenant_name: Apartment::Tenant.current) ||
      Domain.new(tenant_name: 'public', join_type: 'open')
  end
end
