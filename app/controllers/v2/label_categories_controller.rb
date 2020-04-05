module V2
  class LabelCategoriesController < ApplicationController
    before_action :authenticate_user!

    def index
      label_category = LabelCategory.order(:name).all

      render json: label_category, status: :ok
    end

    def show
      label_category = LabelCategory.find(params[:id])

      render json: label_category, status: :ok, location: [:v2, label_category]
    end

    def create
      label_category = LabelCategory.new(label_category_params)
      label_category.save

      render_errors(label_category.errors.full_messages) && return if label_category.errors.any?

      render json: label_category, status: :created, location: [:v2, label_category]
    end

    def update
      label_category = LabelCategory.find(params[:id])

      label_category.update_attributes(label_category_params)

      render json: label_category, status: :ok, location: [:v2, label_category]
    end

    def destroy
      label_category = LabelCategory.find(params[:id])

      render_errors('Could not delete label category') && return unless label_category.destroy

      render json: label_category, status: :ok, location: [:v2, label_category]
    end

    private

    def label_category_params
      params.require(:data).permit(attributes: [:name])
    end
  end
end
