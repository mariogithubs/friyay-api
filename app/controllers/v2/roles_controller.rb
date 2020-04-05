module V2
  class RolesController < ApplicationController
    before_action :authenticate_user!
    before_action :find_resource

    def remove
      user = User.find(role_params[:user_id])

      render_errors('Please specify valid role.') && return unless role?
      render_errors('Resource not found') && return unless @resource

      render_errors('Unauthorized') && return if removing_owner?(role_params[:role], user)

      user.remove_role role_params[:role], @resource

      render json: @resource, status: :ok
    end

    private

    def role_params
      params.require(:data).permit(:role, :user_id, :topic_id, :tip_id)
    end

    def role?
      Role::TYPES.include?(role_params[:role])
    end

    def removing_owner?(role, user)
      @resource.user == user && role.to_sym == :admin
    end

    def find_resource
      @resource = Topic.without_root.find_by(id: role_params[:topic_id]) if role_params[:topic_id]
      @resource = Tip.find_by(id: role_params[:tip_id]) if role_params[:tip_id]
      @resource ||= current_domain
    end
  end
end
