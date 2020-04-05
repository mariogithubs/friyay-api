module V2
  class UserProfileController < ApplicationController
    before_action :authenticate_user!

    def show
      user_profile = UserProfile.find_by_user_id params[:user_id]

      authorize! :read, user_profile

      render json: UserProfileSerializer.new(user_profile)
    end

    def create
      user_profile = UserProfile.find_by_user_id params[:user_id]

      authorize! :update, user_profile

      render_errors('Profile not found.') && return unless user_profile

      user_profile.attributes = user_profile_clean_params

      if params[:data][:email_notifications]
        user_profile.settings(:email_notifications).attributes = email_notifications_attributes
      end

      user_profile.settings(:domain_follows).attributes = domain_follows_attributes
      user_profile.settings(:ui_settings).attributes = ui_settings_attributes

      user_profile.save

      render_errors(user_profile.errors.full_messages) && return if user_profile.errors.any?

      render json: UserAuthenticatedSerializer.new(user_profile.user, { include: [params[:include]] }), status: :ok
    end

    private

    def user_profile_params
      params.require(:data)
        .require(:attributes)
        .permit(
          [
            :avatar, :background_image, :description,
            :remote_avatar_url, :remote_background_image_url, :resource_capacity,
            user_attributes: [
              :id, :first_name, :last_name, :email,
              :password, :password_confirmation, :current_password
            ]
          ]
        )
    end

    def user_profile_clean_params
      opts = user_profile_params

      return opts unless opts.key?(:user_attributes)
      return opts unless opts[:user_attributes].key?(:password)

      password_attr = opts[:user_attributes][:password]
      password_confirm_attr = opts[:user_attributes][:password_confirmation]
      opts[:user_attributes] = opts[:user_attributes].except!(:password) if password_attr.blank?
      opts[:user_attributes] = opts[:user_attributes].except!(:password_confirmation) if password_confirm_attr.blank?

      opts
    end

    def email_notifications_attributes
      attrs = {}
      params[:data][:email_notifications].each_pair do |key, val|
        next if !allowed_type(key.to_sym) || !allowed_value(val)
        attrs[key.to_sym] = val
      end
      attrs
    end

    def domain_follows_attributes
      return {} unless params[:data][:domain_follows]
      attrs = {}
      params[:data][:domain_follows].each_pair do |key, val|
        next unless %i(follow_all_topics follow_all_domain_member).include?(key.to_s)
        next unless %w(true false).include?(val)
        attrs[key.to_sym] = val
      end
      attrs
    end

    def ui_settings_attributes
      return {} unless params[:data][:ui_settings]
      attrs = {}
      params[:data][:ui_settings].each_pair do |key, val|
        attrs[key.to_sym] = val
      end
      attrs
    end

    def allowed_value(value)
      Notification::FREQUENCY.include?(value)
    end

    def allowed_type(type)
      UserProfile::EMAIL_NOTIFICATION_SETTINGS.include?(type)
    end

    def current_ability
      @current_ability ||= Ability.new(current_user, current_domain)
    end
  end
end
