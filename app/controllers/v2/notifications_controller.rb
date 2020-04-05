module V2
  class NotificationsController < ApplicationController
    before_action :authenticate_user!

    def index
      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1

      params[:filter] ||= :latest

      notifications = current_user.notifications.includes(:user, :notifier, :notifiable)
      notifications = notifications.where.not(notifier_id: current_user.id)
      notifications = filter(notifications, params[:filter])
      notifications = notifications.order(id: :desc)
      notifications = notifications.select { |n| n.notifiable && n.notifier }

      notifications = paginate(notifications)

      page_data = {
        current_page: params[:page][:number].to_i,
        count_on_page: notifications.count,
        total_count:  notifications.total_count,
        total_pages:  notifications.total_pages
      }

      render json: notifications, meta: build_meta_data(page_data)
    end

    def mark_as_read
      notifications = current_user.notifications.where(action: filtering_actions, read_at: nil)
      notifications = notifications.where(id: params[:id].to_i) if params[:id].present?
      notifications.update_all(read_at: DateTime.now.utc)

      render json: {}, status: :ok
    end

    private

    def filtering_actions
      %w(
        someone_comments_on_tip
        someone_mentioned_on_comment
        someone_likes_tip
        someone_shared_topic_with_me
        someone_adds_topic
        someone_commented_on_tip_user_commented
      )
    end

    def filter(notifications, filter_type)
      notifications = notifications.where(action: filtering_actions)

      case filter_type
      when :latest
        return notifications.where(created_at: 1.week.ago..DateTime.now.end_of_day.utc)
      when :all
        return notifications
      else
        return notifications
      end
    end
  end
end
