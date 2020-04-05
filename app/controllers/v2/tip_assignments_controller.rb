module V2
  class TipAssignmentsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!

    def create
      tip = Tip.find_by(id: params[:tip_id])

      # DomainMember because we want to make sure the member is a domain_member
      user = DomainMember.find_by(id: params[:user_id])

      group = Group.find_by(id: params[:group_id])

      render_errors('Tip not found') && return if tip.blank?
      render_errors('User not found') && return if user.blank?
      render_errors('Group not found') && return if group.blank?

      tip.assigned_users << user
      tip.assigned_groups << group

      render json: TipSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok
    end
  end
end
