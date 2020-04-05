module V2
  class DomainRolesController < ApplicationController
    def index
      # We don't have a resource of RoleTypes, just a static list
      render json: { data: Role::DOMAIN_TYPES }, status: :ok
    end

    def update
      user = User.find_by(id: params[:user_id])

      render_errors('Please specify valid role.') && return unless acceptable_role
      render_errors('Unauthorized') && return if removing_owner?(current_role(user), user)

      user.remove_role(current_role(user), current_domain)
      user.add_role(role_params[:role], current_domain) unless member_role?

      convert_membership(user, role_params[:role])

      render json: UserSerializer.new(user, { params: { domain: current_domain } }), status: :ok
    end

    private

    def role_params
      params.require(:data).permit(:role)
    end

    def convert_membership(user, role)
      case role
      when 'guest'
        user.leave(current_domain, as: 'member')
        user.leave(current_domain, as: 'power')
        user.join(current_domain, as: 'guest')
      when 'member', nil, ''
        user.leave(current_domain, as: 'power')
        user.leave(current_domain, as: 'guest')
        user.join(current_domain, as: 'member')
      when 'power', nil, ''
        user.leave(current_domain, as: 'member')
        user.leave(current_domain, as: 'guest')
        user.join(current_domain, as: 'power')
      end
    end

    def current_role(user, domain = current_domain)
      @current_role ||= user.roles.current_for_domain(domain).name
    end

    def acceptable_role
      return true if member_role? or power_role? # default
      return true if Role::TYPES.include?(role_params[:role])

      false
    end

    def member_role?
      ['member', '', nil].include? role_params[:role]
    end

    def power_role?
      ['power', '', nil].include? role_params[:role]
    end

    def removing_owner?(role, user)
      current_domain.user == user && role.to_sym == :admin
    end
  end
end
