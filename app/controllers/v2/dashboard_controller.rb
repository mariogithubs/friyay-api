module V2
  class DashboardController < ApplicationController
    before_action :authenticate_user!

    def index
      # determine admin or user
      # return appropriate stats as a JSON API hash
      render_errors("That page doesn't exist.") && return unless admin_list.include?(current_user.email)

      stats = TipHive::GlobalStats.stats

      render json: stats, status: :ok
    end

    private

    def admin_list
      %w(
        anthonylassiter@gmail.com
        anthony@friyay.io
        madiken@friyay.io
        joost@tiphvie.com
        wentinkjoost@gmail.com
        mscholl87@gmail.com
        shannice@friyay.io
      )
    end
  end
end
