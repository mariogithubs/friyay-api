module V2
  class ContextsController < ApplicationController
    before_action :authenticate_user!, except: [:suggested_topics]
    before_action :authorize_on_domain!, except: [:suggested_topics]

    def index
      if context_params.key?(:topic_id)
        contexts = Context.where(topic_id: context_params[:topic_id])
      else
        contexts = Context.all
      end

      render json: contexts
    end

    def create
      # 1. try to find existing context
      # 2. if not, create a new context (setting default: true if first one in topic)

      context_id = Context.generate_id(
        user: current_user.id,
        domain: current_domain.id,
        topic: context_params[:topic_id],
        tip: context_params[:tip_id]
      )

      context = Context.find_by(context_uniq_id: context_id)
      render json: context && return unless context.blank?

      context = Context.create(context_uniq_id: context_id)

      render json: context, status: :created
    end

    def destroy
    end

    private

    def context_params
      params.permit(:context_id, :topic_id, :tip_id)
    end
  end
end
