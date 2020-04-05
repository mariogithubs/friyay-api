class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  # protect_from_forgery with: :null_session -
  # http://apidock.com/rails/v2.0.0/ActionController/RequestForgeryProtection/ClassMethods/protect_from_forgery
  before_action :analyze_information

  # Rescue all errors and returns appropriate friendly error message and code instead of raising exceptions
  include CustomErrorRescue

  def bad_slug?(object)
    params[:id] != object.to_param
  end

  ##
  # 301 redirect to canonical slug.
  def redirect_to_good_slug(object)
    redirect_to url_for(
      params.merge(
        controller: controller_name,
        action: params[:action],
        id: object.to_param
      )
    ), status: :moved_permanently
  end

  def current_domain
    Domain.find_by(tenant_name: Apartment::Tenant.current) || Domain.new(tenant_name: 'public', join_type: 'open')
  end

  def subdomain
    host = URI.parse(request.env['HTTP_ORIGIN']).host
    ActionDispatch::Http::URL.extract_subdomain(host, 1) # tld_length = 1
  end

  # Called by last route matching unmatched routes.
  # Raises RoutingError which will be rescued from in the same way as other exceptions.
  def raise_not_found!
    message = "No route matches #{request.method.upcase} #{params[:unmatched_route]}"
    render json: { errors: { title: message } }, status: :not_found
  end

  # Override redirect_to show redirection flow
  def redirect_to(options = {}, response_status = {})
    logger.info("==> Redirected by #{caller(1).first || 'unknown'}")
    super(options, response_status)
  end

  def paginate(resources)
    return resources if params[:pager] == 'false'

    if resources.is_a?(Array)
      Kaminari.paginate_array(resources).page(params[:page].try(:[], :number)).per(params[:page].try(:[], :size))
    else
      resources.page(params[:page].try(:[], :number)).per(params[:page].try(:[], :size))
    end
  end

  def filter_as_nested_resource(params)
    filter = params[:filter] || {}
    filter[:current_user_id] = current_user.id
    filter[:current_user] = current_user

    case
    when params.key?(:topic_id)
      # TODO: REMOVE AFTER 12-31-2016 IF NO PROBLEMS
      # THIS IS THE KEY TO WHY HIVES DON'T SHOW SUBHIVES
      # BECAUSE AFTER MOVING, WE DON'T TRIGGER THE FOLLOW B/C
      # IT SHOULDN'T BE NECESSARY, A HIVE SHOULD ALWAYS SHOW ITS DESCENDANTS
      # WE JUST NEED TO MAKE SURE THAT REMOVING THIS DOESN'T HAVE UNINTENDED SIDE EFFECTS
      # filter[:following_topic] = params[:topic_id]
    when params.key?(:user_id)
      filter[:created_by] = params[:user_id]
    end

    filter
  end

  def authorize_on_domain!
    return true if %w(public support).include?(current_domain.tenant_name)
    return true if current_user.member_of?(current_domain)
    return true if current_user.power_of?(current_domain)
    return true if current_user.guest_of?(current_domain)

    message = "You are not a member of #{current_domain.tenant_name}.friyayapp.io"
    render json: { errors: [message] }, status: :unauthorized
  end

  def authorize_profiler
    return if ENV['TECH_ADMINS'].blank? || Rails.env.development?
    return unless Rack::MiniProfiler

    Rack::MiniProfiler.authorize_request if current_user && ENV['TECH_ADMINS'].split(',').include?(current_user.email)
  end

  def current_date
    Date.today
  end

  def prev_week_start
    current_date.at_beginning_of_week-8
  end

  def prev_week_end
    prev_week_start.at_end_of_week + 6
  end

  private

  def analyze_information
    Rails.logger.info "====> current_domain: #{current_domain.inspect}"
  end

  def render_errors(error_messages, status = :unprocessable_entity)
    detail = error_messages.is_a?(Array) ? error_messages : [error_messages]
    render json: { errors: { title: 'Something went wrong', detail: detail } }, status: status
  end

  def render_conflict(error_messages, existing_resource, status = 409)
    render_errors(error_messages) && return unless existing_resource

    detail = { resource_slug: existing_resource.slug }
    render json: { errors: { title: 'We found an existing item', detail: detail } }, status: status
  end

  def render_empty_set
    render json: { data: [] }, status: :ok
  end

  def build_meta_data(extra_options = {})
    {
      current_domain: current_domain.tenant_name,
      current_company: current_domain.name
    }.merge(extra_options)
  end

  def verify_recaptcha
    true
    # return true if Rails.env == 'development' || Rails.env == 'test'

    # # rubocop:disable Style/AlignParameters
    # verify_response = HTTParty.post 'https://www.google.com/recaptcha/api/siteverify',
    #                   body: { secret: ENV['RECAPTCHA_SECRET'], response: params[:recaptcha_response] }
    # # rubocop:enable Style/AlignParameters

    # verify_response['success']
  end
end
