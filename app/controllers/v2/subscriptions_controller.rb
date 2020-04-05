module V2
  class SubscriptionsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!
    before_action :check_plans, only: [:create]

    def create
      render_errors('domain stripe customer id is not saved') && return if current_domain.stripe_customer_id.blank?
      render_errors('domain stripe card id is not saved') && return if current_domain.stripe_card_id.blank?
      begin
        subscription = StripeTool.create_subscription(current_domain.stripe_customer_id, subscription_params["basic_users_count"], subscription_params["power_users_count"], subscription_params["admin_users_count"], subscription_params["guest_users_count"], @plan1.stripe_plan_id, @plan2.stripe_plan_id, @plan3.stripe_plan_id, @plan4.stripe_plan_id) if subscription_params["tenure"] == "month"
        subscription = StripeTool.create_subscription_with_discount(current_domain.stripe_customer_id, subscription_params["basic_users_count"], subscription_params["power_users_count"], subscription_params["admin_users_count"], subscription_params["guest_users_count"], @plan1.stripe_plan_id, @plan2.stripe_plan_id, @plan3.stripe_plan_id, @plan4.stripe_plan_id) if subscription_params["tenure"] == "year"
        dbase_subscription = Subscription.create(stripe_subscription_id: subscription["id"], domain_id: current_domain.id, start_date: subscription["created"], tenure: subscription_params["tenure"])
        render_errors(dbase_subscription.errors.full_messages) && return if dbase_subscription.errors.any?
      rescue Stripe::CardError, Stripe::InvalidRequestError => e
        render_errors(e.message)
      end
      render json: subscription, status: :ok
    end

    def update
      dbase_subscription = Subscription.find_by(domain_id: params[:id])
      render_error("Can't find subscription by domain id") && return if dbase_subscription.nil?
      subscription = StripeTool.update_subscription(dbase_subscription.stripe_subscription_id, dbase_subscription.tenure, subscription_params["basic_users_count"], subscription_params["power_users_count"], subscription_params["admin_users_count"], subscription_params["guest_users_count"])
      render json: subscription, status: :ok
    end
  
    def upgrade_request
      if current_domain and current_domain.users
        current_domain.users.each do |user|
          NotificationMailer.upgrade_subscription_request(current_user, user, params[:role]).deliver_now if user.admin_of?(current_domain) || user.id == current_domain.user_id
        end
      end
      render json: {}, status: :ok
    end

    def show
      subscription = Subscription.find_by(domain_id: params[:id])
      render_error("Can't find subscription by domain id") && return if subscription.nil?
      render json: subscription, status: :ok
    end
    
    def check_plans
      render_errors('tenure should be month or year') && return if subscription_params["tenure"] != "month" and subscription_params["tenure"] != "year"
      @plan1 = SubscriptionPlan.where(name: "basic-user-#{plan["tenure"]}").first
      @plan2 = SubscriptionPlan.where(name: "power-user-#{plan["tenure"]}").first
      @plan3 = SubscriptionPlan.where(name: "admin-user-#{plan["tenure"]}").first
      @plan4 = SubscriptionPlan.where(name: "guest-user-#{plan["tenure"]}").first
      render_errors('plans are not defined') && return if @plan1.blank? || @plan2.blank? || @plan3.blank? || @plan4.blank?
    end

    private

    def subscription_params
      params.require(:data).require(:attributes).permit(:tenure, :basic_users_count, :power_users_count, :admin_users_count, :guest_users_count)
    end

    def plan
      opts = subscription_params
      return opts unless opts.key?(:attributes)
      return opts unless opts[:attributes].key(:tenure)
    end

  end  
end
