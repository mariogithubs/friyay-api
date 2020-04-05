module V2
  class BulkActionsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!
    # before_action :set_paper_trail_whodunnit

    def archive
      selected_tips = Tip.where(id: params[:tip_ids])

      archived_tips = []
      unarchived_tips = []
      selected_tips.each do |tip|
        if authorization_check(tip, :can_update)
          tip.archive!
          archived_tips << tip
        else
          unarchived_tips << tip
        end
      end

      render json: { tips: { archived_tips: archived_tips, unarchived_tips: unarchived_tips } }
    end

    def organize
      selected_tips = Tip.where(id: params[:tip_ids])
      topics = Topic.where(id: params[:topic_ids])

      selected_tips.each do |tip|
        topics.each do |topic|
          tip.follow topic unless tip.following?(topic)
        end
      end

      render json: {}, status: :ok
    end

    def share
      selected_tips = Tip.where(id: params[:tip_ids])
      users = User.where(id: params[:user_ids])

      selected_tips.each do |tip|
        tip.share_with_user_resources(users)
      end

      render json: {}, status: :ok
    end

    private

    def authorization_check(tip, action)
      p tip.abilities(current_user)
      return true if tip.abilities(current_user)[:self][action]
    end
  end
end
