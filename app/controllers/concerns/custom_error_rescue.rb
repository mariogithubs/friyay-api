module CustomErrorRescue
  extend ActiveSupport::Concern

  included do
    # continue to use rescue_from in the same way as before
    rescue_from Exception, with: :render_error unless Rails.env == 'test'
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_error
    rescue_from CanCan::AccessDenied, with: :render_unauthorized
    # rescue_from CanCan::AccessDenied, with: :render_error
  end

  private

  # render 500 error
  def render_error(e)
    return e if Rails.env == 'development'
    # ExceptionNotifier.notify_exception(e, env: request.env, data: {})
    friendly_message = 'Request failed. There is an error in the system'
    logger.error "===> EXCEPTION OCCURRED - 500 - Internal Server Error: #{e.message}"
    e.backtrace.each do |line|
      logger.error "===> #{line}"
    end

    render json: { errors: { title: friendly_message } }, status: :internal_server_error
  end

  # render 404 error
  def render_not_found(e)
    # ExceptionNotifier.notify_exception(e, env: request.env, data: {})
    friendly_message = 'The location you are trying to access does not exist'
    logger.error "===> EXCEPTION OCCURRED - 404 - Not Found: #{e.message}"
    e.backtrace.each do |line|
      logger.error "===> #{line}"
    end

    render json: { errors: { title: friendly_message } }, status: :not_found
  end

  # render 401 error
  def render_unauthorized(e)
    friendly_message = 'You are not authorized to perform that request.'
    logger.error "===> EXCEPTION OCCURRED: 401 - Unauthorized: #{e.message}"
    e.backtrace.each do |line|
      logger.error "===> #{line}"
    end

    render json: { errors: { title: friendly_message } }, status: :unauthorized
  end
end
