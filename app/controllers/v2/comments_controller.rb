module V2
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    before_action :find_parent_resource, only: [:create]

    def index
      @parent_resource = Tip.find_by_id(params[:tip_id]) if params[:tip_id]
      @parent_resource = Question.find_by_id(params[:question_id]) if params[:question_id]

      render_errors('Could not complete request.') && return if @parent_resource.blank?

      comments = @parent_resource.comment_threads.includes(user: :user_profile).order('created_at ASC')

      render json: comments, status: :ok
    end

    def create
      if @parent_resource
        comment = @parent_resource.comment_threads.new(nested_comment_params)
        comment.user = current_user
      else
        comment = Comment.build_from(find_resource, current_user.id, comment_params[:attributes][:body])
      end
      comment.save

      render_errors('Could not create comment') && return if comment.errors.any?

      render json: comment, status: :created, location: [:v2, comment]
    end

    def show
    end

    def update
      comment = current_user.comments.find_by(id: params[:id])

      authorization_checks(comment.try(:commentable))

      comment.update_attributes(comment_params[:attributes])

      render_errors('Could not create comment') && return if comment.errors.any?

      render json: comment, status: :ok, location: [:v2, comment]
    end

    def destroy
      comment = current_user.comments.find_by(id: params[:id])

      render_errors('Comment could not be found') && return if comment.blank?

      render_errors('Comment could not be deleted') && return unless comment.destroy

      render json: {}, status: :no_content
    end

    def reply
      comment = Comment.find(params[:id])

      authorization_checks(comment.try(:commentable))

      render_errors('Comment could not be replied to') && return if comment.errors.any?

      reply = comment.reply_with(comment_params[:attributes][:body])

      render json: reply, status: :ok, location: [:v2, comment]
    end

    def flag
      comment = Comment.find(params[:id])
      comment.create_flaggable_recorded(current_user, params[:reason])

      render json: comment, status: :ok, location: [:v2, comment]
    end

    private

    def comment_params
      params.require(:data)
        .permit(
          :type,
          attributes: [:title, :body, :longitude, :latitude, :location],
          relationships: [
            commentable: [
              {
                data: [
                  :id,
                  :type
                ]
              }
            ]
          ]
        )
    end

    def find_resource
      resource_class = comment_params[:relationships][:commentable][:data][:type].singularize.classify.constantize

      resource_class.find(comment_params[:relationships][:commentable][:data][:id])
    end

    def find_parent_resource
      @parent_resource = Tip.find_by_id(params[:tip_id]) if params[:tip_id]
      @parent_resource = Question.find_by_id(params[:question_id]) if params[:question_id]

      authorization_checks(@parent_resource) if @parent_resource
    end

    def authorization_checks(commentable)
      status = false unless commentable

      (status = commentable.abilities(current_user)[:self][:can_answer])  if commentable.is_a?(Question)
      (status = commentable.abilities(current_user)[:self][:can_comment]) if commentable.is_a?(Tip)

      fail CanCan::AccessDenied unless status
    end

    def nested_comment_params
      params.require(:data)
        .require(:attributes)
        .permit(:title, :body, :longitude, :latitude, :location)
    end
  end
end
