module V2
  class ViewAssignmentsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!

    def create
      view = View.find_by(id: params[:view_id])

      # DomainMember because we want to make sure the member is a domain_member
      user = DomainMember.find_by(id: params[:user_id])

      render_errors('View not found') && return if view.blank?
      render_errors('User not found') && return if user.blank?

      view_assignment = ViewAssignment.create(view_id: view.id, user_id: user.id, domain_id: current_domain.id)
      render_errors(view_assignment.errors.full_messages) && return if view_assignment.errors.any?
      render json: view, status: :ok
    end

  end
end