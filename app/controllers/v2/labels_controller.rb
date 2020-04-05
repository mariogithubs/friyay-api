module V2
  class LabelsController < ApplicationController
    before_action :authenticate_user!

    def index
      # rubocop:disable MultilineOperationIndentation
      query = "kind = 'public' OR kind = 'system' OR (kind = 'private' AND user_id = ?)"
      labels = Label.order(:name)
                    .includes(:label_assignments, :user)
                    .where(query, current_user.id).all
      # rubocop:enable MultilineOperationIndentation

      personal_query = "(user_id IN (?) OR user_id = ? ) OR (kind = 'system')"
      labels = labels.where(personal_query, 
                            current_user.following_users.pluck(:id), 
                            current_user.id) if current_domain.tenant_name == 'public'
      render json: LabelSerializer.new(labels), status: :ok
    end

    def show
      label = Label.find(params[:id])

      render json: LabelSerializer.new(label), status: :ok, location: [:v2, label]
    end

    def create
      label = current_user.labels.new(label_params)
      label.save

      render_errors(label.errors.full_messages) && return if label.errors.any?

      render json: LabelSerializer.new(label), status: :created, location: [:v2, label]
    end

    def update
      label = Label.find(params[:id])

      label.update_attributes(label_params)

      label_assignment = label.label_assignments.where(item_id: params[:item_id], item_type: params[:item_type]).first

      render json: LabelAssignmentSerializer.new(label_assignment), include: 'item', status: :ok, location: [:v2, label]
    end

    def destroy
      label = Label.find(params[:id])
      label_assignment = label.label_assignments.where(item_id: params[:item_id], item_type: params[:item_type]).first

      render_errors('Could not delete card') && return unless label.destroy

      render json: LabelAssignmentSerializer.new(label_assignment), include: 'item', status: :ok, location: [:v2, label]
    end

    private

    def label_params
      params.require(:data).permit(attributes: [:name, :color, :kind, :label_category_ids => []])
    end
  end
end
