module V2
  class PeopleOrdersController < ApplicationController
    before_action :authenticate_user!

    def index
      people_orders = PeopleOrder.all

      render json: people_orders, status: :ok
    end

    def show
      people_order = PeopleOrder.find(params[:id])

      render json: people_order, status: :ok, location: [:v2, people_order]
    end

    def create
      people_order = PeopleOrder.new(people_orders_params)
      people_order.save

      render json: people_order, status: :created, location: [:v2, people_order]
    end

    def update
      people_order = PeopleOrder.find(params[:id])
      people_order.update(people_orders_params)
      render json: people_order, status: :ok, location: [:v2, people_order]
    end

    def destroy
      people_order = PeopleOrder.find(params[:id])

      render_errors('Could not delete people order') && return unless people_order.destroy

      render json: {}, status: 204
    end

    private

    def people_orders_params
      params.require(:data).permit(attributes: [:name, :order => [] ] )
    end
  end
end