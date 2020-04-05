module V2
  class ViewsController < ApplicationController
    # before_action :authenticate_user!
    # before_action :authorize_on_domain!

    def index
      views = View.system

      render json: views, status: :ok
    end

  end
end
