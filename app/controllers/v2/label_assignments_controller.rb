module V2
  class LabelAssignmentsController < ApplicationController
    before_action :authenticate_user!

    def index
      label_assignments = LabelAssignment.where(item_id: params[:item_id], item_type: params[:item_type]).all

      render json: LabelAssignmentSerializer.new(label_assignments), status: :ok
    end

    def show
      label_assignment = LabelAssignment.find(params[:id])

      render json: LabelAssignmentSerializer.new(label_assignment), status: :ok, location: [:v2, label_assignment]
    end

    def create
      # Find existing label assignment
      label_assignment = LabelAssignment.where(label_assignment_params[:attributes]).first
      # We have to grab only the attributes from the params hash
      label_assignment = LabelAssignment.new(label_assignment_params[:attributes]) unless label_assignment
      label_assignment.save

      render_errors(label_assignment.errors.full_messages) && return if label_assignment.errors.any?

      render json: LabelAssignmentSerializer.new(label_assignment), include: 'item', status: :created, location: [:v2, label_assignment]
    end

    def update
      label_assignment = LabelAssignment.find(params[:id])

      render_errors(label_assignment.errors.full_messages) && return if label_assignment.errors.any?

      render json: LabelAssignmentSerializer.new(label_assignment), status: :ok, location: [:v2, label_assignment]
    end

    def destroy
      label_assignment = LabelAssignment.where(label_assignment_params[:attributes]).first
      item = label_assignment.item

      render_errors('Could not delete label assignment') && return unless label_assignment.destroy

      render json: item, status: :ok, location: [:v2, item]
    end

    private

    # def label_assignment_params
    #   params.require(:data)
    #     .permit(:type, relationships: { label: { data: [:id, :type] }, item: { data: [:id, :type] } })
    # end

    # In this specific case, because label_assignment model is just a join table,
    # the related attributes are actually 1st class attributes of the label_assignment
    def label_assignment_params
      params.require(:data).permit(:type, attributes: [:label_id, :item_id, :item_type])
    end
  end
end
