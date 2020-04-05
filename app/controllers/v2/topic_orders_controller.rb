module V2
  class TopicOrdersController < ApplicationController
    before_action :authenticate_user!

    def index
      topic_orders = TopicOrder.all

      render json: topic_orders, status: :ok
    end

    def show
      topic_order = TopicOrder.find(params[:id])

      render json: topic_order, status: :ok, location: [:v2, topic_order]
    end

    def create
      topic_order = TopicOrder.new(topic_orders_params)
      topic_order.save

      topic_order.update_associations(topic_orders_params)
      topic_order.user_relationship(params[:data][:attributes][:user_id]) if params[:data][:attributes][:user_id].present?
      topic_order.set_default_order(topic_orders_params) if (
        topic_orders_params[:attributes][:is_default].present? ||
        TopicOrder.where(topic_id: params[:data][:attributes][:topic_id]).count == 1
      )

      render json: topic_order, status: :created, location: [:v2, topic_order]
    end

    def update
      topic_order = TopicOrder.find(params[:id])
      topic_order.update(topic_orders_params)

      topic_order.update_associations(topic_orders_params)
      topic_order.user_relationship(params[:data][:attributes][:user_id]) if params[:data][:attributes][:user_id].present?
      topic_order.set_default_order(topic_orders_params) if topic_orders_params[:attributes][:is_default].present?
      
      render json: topic_order, status: :ok, location: [:v2, topic_order]
    end

    def destroy
      topic_order = TopicOrder.find(params[:id])

      render_errors('Could not delete topic order') && return unless topic_order.destroy

      render json: {}, status: 204
    end

    private

    def topic_orders_params
      params.require(:data).permit(attributes: [:name, :topic_id, :is_default, :subtopic_order => [], :tip_order => [] ] )
    end
  end
end 
