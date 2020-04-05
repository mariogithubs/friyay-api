module V2
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    def index
      orders = Order.all

      render json: orders, status: :ok
    end

    def show
      order = Order.find(params[:id])

      render json: order, status: :ok, location: [:v2, order]
    end

    def create
      order = Order.new(orders_params)
      order.save

      render json: order, status: :created, location: [:v2, order]
    end

    def update
      order = Order.find(params[:id])
      order.update(orders_params)
      render json: order, status: :ok, location: [:v2, order]
    end

    def destroy
      order = Order.find(params[:id])

      render_errors('Could not delete order') && return unless order.destroy

      render json: order, status: :ok, location: [:v2, order]
    end

    private

    def orders_params
      params.require(:data).permit(attributes: [:title, :is_public] )
    end
  end
end 
