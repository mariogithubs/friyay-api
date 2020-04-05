module V2
  class CardsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!
  
    def create
      render_errors('card token is blank') && return if card_params['stripe_card_token'].blank?
      begin
        customer = StripeTool.create_customer(current_domain.name, current_user.email, card_params['stripe_card_token'])
        current_domain.update_stripe_card_and_customer(card_params['stripe_card_token'], customer['id'])
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message)
      end
      render json: customer, status: :ok
    end

    def update
      render_errors('card token is blank') && return if card_params['stripe_card_token'].blank?
      render_errors('customer id is blank') && return if params[:id].blank?
      begin
        customer = StripeTool.update_customer_card(params[:id], card_params['stripe_card_token'])
        current_domain.update_stripe_card_and_customer(card_params['stripe_card_token'], customer['id'])
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message)
      end
      render json: customer, status: :ok
    end

    private

    def card_params
      params.require(:data).require(:attributes).permit(:stripe_card_token, :stripe_customer_id)
    end

  end
end