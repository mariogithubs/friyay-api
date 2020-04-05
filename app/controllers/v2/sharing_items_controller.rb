module V2
  # Sharable items search controller
  class SharingItemsController < ApplicationController
    include TipHive

    before_action :authenticate_user!

    # GET /v2/sharing_items.json
    def index
      params[:page] = params.try(:[], 'page') || {}
      params[:page][:number] = params[:page].try(:[], 'number') || 1
      params[:page][:size]   = params[:page].try(:[], 'size') || 30

      search = SearchService.new(current_domain, current_user, params)
      @sharing_items = search.sharing_items

      render json: @sharing_items, status: :ok
    end
  end
end
