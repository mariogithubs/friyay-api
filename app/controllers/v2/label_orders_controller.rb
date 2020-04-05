module V2
  class LabelOrdersController < ApplicationController
    before_action :authenticate_user!

    def index
      label_orders = LabelOrder.all

      render json: label_orders, status: :ok
    end

    def show
      label_orders = LabelOrder.find(params[:id])

      render json: label_orders, status: :ok, location: [:v2, label_orders]
    end

    def create
      label_orders = LabelOrder.new(label_orders_params)
      label_orders.save

      render json: label_orders, status: :created, location: [:v2, label_orders]
    end

    def update
      label_orders = LabelOrder.find(params[:id])
      LabelOrder.update_all(is_default: false) if label_orders_params[:attributes][:is_default].present?
      label_orders.update(label_orders_params)
      render json: label_orders, status: :ok, location: [:v2, label_orders]
    end

    def destroy
      label_orders = LabelOrder.find(params[:id])

      render_errors('Could not delete label order') && return unless label_orders.destroy

      render json: {}, status: 204
    end

    private

    def label_orders_params
      params.require(:data).permit(attributes: [:name, :is_default, :order => [] ] )
    end
  end
end
