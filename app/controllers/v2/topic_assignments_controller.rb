module V2
  class TopicAssignmentsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!

    def create
      tip = Tip.find_by(id: params[:tip_id])
      topic = Topic.find_by(id: assign_params[:topic_id])

      render_errors('Could not find Tip') && return if tip.blank?
      render_errors('Could not find Topic') && return if topic.blank?

      tip_followers = tip.tip_followers

      tip.follow(topic)

      tip_followers.each do |nested|
        nested.follow(topic)
      end

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :created
    end

    def move
      tip = Tip.find_by(id: params[:tip_id])
      from_topic = Topic.find_by(id: assign_params[:from_topic])
      to_topic = Topic.find_by(id: assign_params[:to_topic])

      render_errors('Could not find Tip') && return if tip.blank?
      render_errors('Could not find Topic') && return unless from_topic
      render_errors('Could not find Topic') && return unless to_topic

      tip_followers = tip.tip_followers

      tip.follow(to_topic)
      tip.stop_following(from_topic)

      tip_followers.each do |nested|
        nested.follow(to_topic)
        nested.stop_following(from_topic)
      end 

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok
    end

    private

    def assign_params
      params.require(:data).permit(:topic_id, :from_topic, :to_topic)
    end
  end
end
