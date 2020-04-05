module V2
  class PasswordsController < ApplicationController
    # POST /resource/password
    def create
      @user = User.send_reset_password_instructions(user_params)

      if successfully_sent?(@user)
        msg = 'You will receive an email with instructions on how to reset your password in a few minutes.'
        render json: { message: msg }, status: :ok
      else
        msg = 'Could not send your password reset instructions email, please try again.'
        render json: { errors: [msg] }, status: :unprocessable_entity
      end
    end

    # PUT /resource/password
    def update
      @user = User.reset_password_by_token(user_params)

      if @user.errors.empty?
        @user.unlock_access! if unlockable?(@user)
        if Devise.sign_in_after_reset_password
          # msg = 'Your password has been changed successfully. You are now signed in.'
          sign_in @user, store: true
          render json: @user, serializer: UserAuthenticatedSerializer, status: :ok
        else
          msg = 'Your password has been changed successfully.'
          render json: { message: msg }, status: :ok
        end
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    protected

    # Check if proper Lockable module methods are present & unlock strategy
    # allows to unlock resource on password reset
    def unlockable?(user)
      user.respond_to?(:unlock_access!) &&
        user.respond_to?(:unlock_strategy_enabled?) &&
        user.unlock_strategy_enabled?(:email)
    end

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
    end

    def successfully_sent?(user)
      notice = if Devise.paranoid
                 user.errors.clear
                 :send_paranoid_instructions
               elsif user.errors.empty?
                 :send_instructions
               end

      true if notice
    end
  end
end
