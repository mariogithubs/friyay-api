class PagesController < ApplicationController
  before_action :authorize_profiler

  def authorize_profiler
    return unless ENV['TECH_ADMINS']

    Rack::MiniProfiler.authorize_request if current_user && ENV['TECH_ADMINS'].split(',').include?(current_user.email)
  end

  # Rack mini-profiler information page
  def mini_profiler
    render 'pages/mini_profiler'
  end
end
