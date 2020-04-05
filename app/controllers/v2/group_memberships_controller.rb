module V2
  class GroupMembershipsController < ApplicationController
    before_action :authenticate_user!

    def index
      group = Group.find_by(id: params[:group_id])
      render_errors('Could not find group') && return unless group.present?
      user_followers = group.user_followers

      render json: UserSmallSerializer.new(
        user_followers,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, meta: build_meta_data(count: user_followers.count)
    end

    def create
      group = Group.find_by(id: params[:group_id])
      render_errors('Could not find group') && return unless group.present?
      user_array = [user_params].flatten
      users = User.where(id: user_array.map { |u| u[:id] })

      users.each { |user| user.follow(group) }

      users = group.user_followers

      render json: UserSmallSerializer.new(
        users,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :created, meta: build_meta_data(count: users.count)
    end

    def destroy
      group = Group.find_by(id: params[:group_id])
      render_errors('Could not find group') && return unless group.present?

      user = User.find_by(id: params[:id])
      render_errors('Could not find group') && return unless user.present?

      user.stop_following(group)
      users = group.user_followers

      render json: UserSmallSerializer.new(
        users,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, meta: build_meta_data(count: users.count)
    end

    private

    def user_params
      params.require(:data)
    end
  end
end
