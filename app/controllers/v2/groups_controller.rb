module V2
  class GroupsController < ApplicationController
    before_action :authenticate_user!

    def index
      groups = current_user.following_groups

      render json: groups
    end

    def show
      group = current_user.groups.find_by(id: params[:id]) || current_user.following_groups.find_by(id: params[:id])

      render json: group, serializer: GroupDetailSerializer
    end

    def create
      group = current_user.groups.new(group_params[:attributes])
      group.save

      render_errors(group.errors.full_messages) && return if group.errors.any?

      relationships = params['data']['relationships']
      subtopics = relationships['subtopics'] if relationships.present?

      group.follow_multiple_resources(:topic, subtopics, current_user) if subtopics.present?

      current_user.follow(group)
      group.share_with_all_relationships(params)

      render json: group, status: :created, location: [:v2, group], serializer: GroupDetailSerializer
    end

    def update
      group = Group.find_by(id: params[:id])
      render_errors(group.errors.full_messages) && return if group.nil?

      group.attributes = group_params[:attributes]
      group.save

      render_errors(group.errors.full_messages) && return if group.errors.any?

      relationships = params['data']['relationships']
      subtopics = relationships['subtopics'] if relationships.present?

      group.follow_multiple_resources(:topic, subtopics, current_user) if subtopics.present?

      group.share_with_all_relationships(params)

      render json: group, status: :ok, location: [:v2, group], serializer: GroupDetailSerializer
    end

    def destroy
      group = Group.find_by(id: params[:id])

      render_errors('Could not delete group') && return unless group.destroy

      render json: {}, status: :no_content
    end

    # def join
    #   group = Group.find(params[:id])
    #   result = group.add_member(current_user)

    #   render_errors(result[:message]) && return if result[:success] == false

    #   render json: group, status: :ok, location: [:v2, group], serializer: GroupDetailSerializer
    # end

    # def request_invitation
    #   # TODO: does this need to be Invitation::create ?
    #   # Do we redirect, or inform the consuming app to send a request to Invitation
    #   # Or do we want to return an invitation object or a group object?
    #   group = Group.find(params[:id])
    #   invitation = group.invite(current_user)

    #   render_errors(invitation.errors.full_messages) && return if invitation.errors.any?

    #   render json: invitation, status: :ok, location: [:v2, group], serializer: GroupDetailSerializer
    # end

    def follows
      group = Group.find_by(id: params[:id])

      render json: group, status: :ok, serializer: GroupFollowsSerializer
    end

    private

    def group_params
      params.require(:data)
        .permit(
          :type,
          relationships: [user_followers: { data: [:id, :type] }],
          attributes: [:title, :description, :join_type,
                       :avatar, :background_image,
                       :remote_avatar_url, :remote_background_image_url]
        )
    end

    def ask_for_invite
      true
    end
  end
end
