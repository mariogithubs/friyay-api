module V2
  class UsersController < ApplicationController
    before_action :authenticate_user!, except: [:decode_token]
    before_action :set_page_param, only: [:index]

    def index
      users = current_domain
              .users
              .order(:first_name)
              .filter_with_current_user(current_user, params[:filter])

      render_empty_set && return if users.blank?

      users = paginate(users.where.not(id: current_user).uniq)

      render_empty_set && return if users.blank?

      page_data = {
        current_page: params[:page][:number].to_i,
        count_on_page: users.count,
        total_count:  users.total_count,
        total_pages:  users.total_pages
      }

      if params[:with_details].present?
        render json: users, each_serializer: UserDetailSerializer,
               meta: build_meta_data(page_data.merge(count: users.count))
        return
      end

      render json: UserSerializer.new(
        users,
        {
          params: {
            domain: current_domain
          },
          include: ['user_profile']
        }).serializable_hash.merge({ meta: build_meta_data(page_data.merge(count: users.count)) })
    end

    def me
      render json: UserAuthenticatedSerializer.new(current_user, { include: ['user_topic_label_order', 'user_topic_people_order', 'user_profile']})
    end

    def show
      @user = User.find_by(id: params[:id])
      @user ||= User.where('lower(users.username) = ?', params[:id].downcase).first

      render_errors('Domain Member not found') && return unless @user

      unless @user.member_or_power_or_guest_of?(current_domain)
        render_errors('Domain Member not found')
        return
      end

      render json: UserDetailSerializer.new(
        @user,
        {
          params: {
            domain: current_domain
          },
          include: ['user_profile']
        }
      )
    end

    def create
      # HANDLED IN REGISTRATIONS CONTROLLER
    end

    def public_token_switch!
      Rails.logger.info "====> Start PUBLIC TOKEN SWITCH params[:token]: #{params[:token]}"
      return if current_domain.id != ENV['SUPPORT_DOMAIN_ID'].to_i

      support_user = User.find_by_id(ENV['SUPPORT_USER_ID'])
      Rails.logger.info "====> Find support_user: #{support_user}"
      return if support_user.blank?

      return { guest_auth_token: support_user.try(:auth_token) } if params[:token].blank?

      decoded_data = JsonWebToken.decode(params[:token])
      Rails.logger.info "====> PUBLIC TOKEN SWITCH decoded_data: #{decoded_data}"
      user_id = decoded_data['user_id'].to_i
      user = User.find_by_id(user_id)
      Rails.logger.info "====> Find decoded user: #{user.inspect}"
      return if user.blank?

      params[:token] = support_user.try(:auth_token) unless (user.member_of?(current_domain) || user.power_of?(current_domain))
    end

    def decode_token # rubocop:disable PerceivedComplexity
      decoded_data = public_token_switch!
      Rails.logger.info "====> DECODE TOKEN decoded_data: #{decoded_data}"

      if params[:token].present?
        decoded_data = JsonWebToken.decode(params[:token])
        Rails.logger.info "====> DECODE TOKEN params[:token]:#{params[:token]} - decoded_data: #{decoded_data}"

        render_errors("Failed to decode authentication token: #{decoded_data}") && return if decoded_data.is_a?(String)
        render_errors('Invalid token format') && return unless decoded_data.is_a?(Hash)
      elsif decoded_data.blank?
        render_errors("Didn't receive authentication token") && return
      end

      render json: decoded_data, status: :ok
    end # rubocop:enable PerceivedComplexity

    def follow
      user_to_follow = User.find(params[:id])
      render_errors('No user found') && return if user_to_follow.blank?

      current_user.follow(user_to_follow)

      render json: UserDetailSerializer.new(
        user_to_follow,
        {
          params: {
            domain: current_domain
          },
          include: [params[:include]]
        }
      ), status: :ok
    end

    def unfollow
      user_to_follow = User.find_by(id: params[:id])
      render_errors('No user found') && return if user_to_follow.blank?

      current_user.stop_following(user_to_follow)

      render json: { data: [] }, status: :ok
    end

    def update_order
      user = User.find_by(id: params[:id])
      user.update_order(params[:data])

      render json: UserDetailSerializer.new(
        user,
        {
          params: {
            domain: current_domain
          },
          include: [params[:include]]
        }
      ), status: :ok
    end

    def follows
      user = User.find_by(id: params[:id])

      render json: user, status: :ok, serializer: UserFollowsSerializer
    end  

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :username)
    end

    def set_page_param
      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1
      params[:filter] = params[:filter] || { users: 'following' }
    end
  end
end
