module V2
  class ConnectionsController < ApplicationController
    before_action :authenticate_user!
    before_action :build_follow_params
    before_action :authorize_on_domain!

    def index
      render json: { message: 'no' } && return unless Rails.env == 'development'

      connections = Follow.all

      render json: connections, include: 'follower,followable'
    end

    def create
      connection = create_next_connection
      remove_previous_connection

      render json: FollowSerializer.new(
        connection,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :created, location: v2_connections_url(connection)
    end

    def update
      connection = create_next_connection
      remove_previous_connection

      render json: FollowSerializer.new(
        connection,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: v2_connections_url(connection)
    end

    def destroy
      follower = @previous_follow[:follower_type]
                 .constantize
                 .find_by(id: @previous_follow[:follower_id])

      fail CanCan::AccessDenied unless current_user.can?(:update, follower)

      # TODO: Create tests
      # render json: { message: 'no' } && return unless Rails.env == 'development'

      connection = Follow.find_by(@previous_follow)
      connection.destroy

      render json: {}, status: 204
    end

    private

    def connection_params
      params.require(:data)
        .permit(
          :type,
          # attributes: [:follower_type, :follower_id, :followable_type, :followable_id]
          attributes: {
            previous: {
              follower: [:id, :type],
              followable: [:id, :type]
            },
            next: {
              follower: [:id, :type],
              followable: [:id, :type]
            }
          }
        )
    end

    def reorder_params
      params.require(:data)
        .require(:reorder)
        .permit(:topic_id, :context_id, preceding_tips: [])
    end

    def build_follow_params
      @previous_follow = follow_params(connection_params[:attributes][:previous])
      @next_follow = follow_params(connection_params[:attributes][:next])
    end

    def create_next_connection
      return if @next_follow.blank?

      follower = @next_follow[:follower_type]
                 .constantize
                 .find_by(id: @next_follow[:follower_id])

      fail CanCan::AccessDenied unless current_user.can?(:update, follower)
      connection = Follow.new(@next_follow)
      connection.save

      reorder_tip(follower) if follower.is_a?(Tip)

      render_errors(connection.errors.full_messages) && return if connection.errors.any?

      connection
    end

    def remove_previous_connection
      return if @previous_follow.blank?

      previous_follow = Follow.find_by(@previous_follow)
      previous_follow.destroy
    end

    def follow_params(unfiltered)
      return nil if unfiltered.blank?

      follower = unfiltered[:follower]
      followable = unfiltered[:followable]
      {
        follower_type: follower[:type],
        follower_id: follower[:id],
        followable_type: followable[:type],
        followable_id: followable[:id]
      }
    end

    def reorder_tip(tip)
      return if @next_follow[:follower_type] != 'Tip'
      return unless params[:data].key?(:reorder) && reorder_params.key?(:topic_id)

      reorder_results = ReorderService.new(
        user: current_user,
        domain: current_domain,
        resource: tip,
        topic_id: reorder_params[:topic_id],
        tip_id: connection_params[:attributes][:followable_id],
        context_id: reorder_params[:context_id],
        preceding_resources: reorder_params[:preceding_tips]
      )

      reorder_results.reorder

      tip.position = reorder_results.new_resource_position

      # TODO: Write a custom exception rescue that logs this error
    ensure
      tip
    end
  end
end
