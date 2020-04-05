module V2
  class TiphiveBotController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!
    before_action :set_paper_trail_whodunnit

    include TipConcern

    def get_tiphive_bot_data
      tips = current_user.tips
      data = {

        # today's tips status
        current_day_tip_status: current_day_tip_status(tips),

        # weekly status
        weekly_tip_status: weekly_tip_status(tips),

        # Individual topic's cards status
        topic_based_cards_status: topic_based_cards_status,

        # Assignee weekly status
        any_assignee_cards_weekly_status: any_assignee_cards_weekly_status(current_user.id),

        # Workspace weekly status
        workspace_card_weekly_status: workspace_card_weekly_status,

        # card clean status
        card_clean_up_status: card_clean_up_status
      }
      render json: data
    end

    def get_users_and_topics
      users = current_domain.domain_members.where("first_name ILIKE :query OR last_name ILIKE :query", {:query => "%#{params[:query]}%"}).limit(10)
      users = users.to_a.uniq(&:email)
      if current_domain.tenant_name == "public"
        ids = current_user.followers.map(&:id)
        ids << current_user.id
        users = User.where(id: ids).where("first_name ILIKE :query OR last_name ILIKE :query", {:query => "%#{params[:query]}%"}).limit(10)
      end
      topics = Topic.where("title ILIKE ?", "%#{params[:query]}%").limit(10)
      render json: { users: UserSerializer.new(users), topics: topics }
    end

    def get_bot_data_using_command
      command = params[:text]
      if params[:topic_id].present? || params[:user_id].present?
        case command
        when 'status'
          get_status_by_command
        when 'cards due'
          get_cards_due_by_command
        when 'cards completed'
          get_cards_completed_by_command
        when 'cards in progress'
          get_cards_in_progress_by_command
        when 'this week'
          get_cards_this_week_by_command
        else
          render json: {message: "invalid command"}, status: :ok
        end
      else
      	render json: {message: "please select any user or topic"}, status: :ok
      end
    end

    private

    def current_day_tip_status(tips)
      card_overdue_today = tips.where(due_date: current_date...current_date+1, completion_date: nil)
      card_overdue_with_assigned_users = get_assign_user(card_overdue_today)
      card_complete_today = tips.where(completion_date: current_date...current_date+1)
      card_complte_assigned_users = get_assign_user(card_complete_today)
      card_at_risk_today = tips.where("due_date < ? AND completed_percentage =  ? ", current_date-2, 0)
      card_at_risk_assigned_users = get_assign_user(card_at_risk_today)
      card_started = tips.where(start_date: current_date...current_date+1)
      { card_overdue_today: card_overdue_with_assigned_users, card_complete_today: card_complte_assigned_users, card_at_risk_today: card_at_risk_assigned_users, card_started: get_assign_user(card_started) }
    end

    def weekly_tip_status(tips)
      card_complete_weekly = tips.where(completion_date: prev_week_start..prev_week_end)
      card_complte_assigned_users = get_assign_user(card_complete_weekly)
      card_overdue_weekly = tips.where("due_date < ? AND completion_date IS ?", current_date, nil)
      card_overdue_with_assigned_users = get_assign_user(card_overdue_weekly)
      card_unstarted_weekly = tips.where("start_date < ? AND completed_percentage = ?", current_date, 0)
      card_unstarted_assigned_users = get_assign_user(card_unstarted_weekly)
      { card_complete_weekly: card_complte_assigned_users, card_overdue_weekly: card_overdue_with_assigned_users, card_unstarted_weekly: card_unstarted_assigned_users, week_end_date: prev_week_end }
    end

    def topic_based_cards_status
      topics = Topic.all
      topic_based_cards = []
      topics.each do |topic|
        topic_with_tips = {}
        tips = pick_tips(topic_id: topic.id)
        topic_with_tips["title"] = topic.title
        topic_with_tips["card_title"] = weekly_tip_status(tips)
        topic_based_cards << topic_with_tips if topic_have_cards(topic_with_tips["card_title"])
      end
      topic_based_cards
    end

    def topic_have_cards(topic_data)
      topic_data[:card_complete_weekly].present? || topic_data[:card_overdue_weekly].present? || topic_data[:card_unstarted_weekly].present?
    end

    def any_assignee_cards_weekly_status(user_id)
      tips = get_assignee_cards(user_id)
      weekly_tip_status(tips)
    end

    def get_assignee_cards(user_id)
      User.find_by(id: user_id).assigned_tips
    end

    def workspace_card_weekly_status
      tips = Tip.all
      weekly_tip_status(tips)
    end

    def card_clean_up_status
      card_created_older_than_year = Tip.where("created_at < ?", 1.year.ago.beginning_of_month)
      card_without_activity_for_six_month = Tip.where("updated_at < ?", 6.month.ago.beginning_of_month)
      { card_created_older_than_year__title: get_assign_user(card_created_older_than_year), card_without_activity_for_six_month_title: get_assign_user(card_without_activity_for_six_month) }
    end

    def get_assign_user(tips)
      card_with_assign_user = []
      tips.each do |tip|
        tips_assign_user = {}
        tips_assign_user["assignee"] = tip.assigned_users.map(&:first_name)
        tips_assign_user["title"] = tip.title
        tips_assign_user["id"] = tip.id
        tips_assign_user["updated_at"] = tip.updated_at
        card_with_assign_user << tips_assign_user
      end
      card_with_assign_user
    end

    def get_status_by_command
      if params[:topic_id].present? && params[:user_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        tips_for_given_user = get_tips_for_given_user(tips)
        tips = get_tips(tips_for_given_user)
        render json: {title: params[:title], topic_based_cards_status: tip_status_by_command(tips), user_and_topic: true}, status: :ok
      elsif params[:topic_id].present? && !params[:user_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        tips = get_tips(tips.map(&:id))
        render json: {title: params[:title], topic_based_cards_status: tip_status_by_command(tips) }, status: :ok
      elsif params[:user_id].present?
        render json: {title: params[:title], any_assignee_cards_weekly_status: any_assignee_cards_status_by_command(params[:user_id]) }, status: :ok
      end
    end

    def tip_status_by_command(tips)
      card_complete = tips.where.not(completion_date: nil)
      card_overdue = tips.where("due_date < ? AND completion_date IS ?",current_date, nil)
      card_unstarted = tips.where("start_date < ?", current_date).where(completion_date: nil, completed_percentage: 0)
      card_in_progress = tips.where("start_date < ?",current_date+1).where(completion_date: nil, completed_percentage: 1..99)
      { card_complete_weekly: get_assign_user(card_complete), card_overdue_weekly: get_assign_user(card_overdue), card_unstarted_weekly: get_assign_user(card_unstarted), card_in_progress: get_assign_user(card_in_progress), week_end_date: current_date }
    end

    def any_assignee_cards_status_by_command(user_id)
      tips = get_assignee_cards(user_id)
      tip_status_by_command(tips)
    end

    def get_cards_due_by_command
      if params[:topic_id].present? && params[:user_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        tip_ids = get_tips_for_given_user(tips)
        over_due_card_by_command(tip_ids)
      elsif params[:topic_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        over_due_card_by_command(tips.map(&:id))
      elsif params[:user_id].present?
        tips = get_assignee_cards(params[:user_id])
        over_due_card_by_command(tips.map(&:id))
      end
    end

    def get_cards_completed_by_command
      if params[:topic_id].present? && params[:user_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        tip_ids = get_tips_for_given_user(tips)
        cards_completed_by_command(tip_ids)
      elsif params[:topic_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        cards_completed_by_command(tips.map(&:id))
      elsif params[:user_id].present?
        tips = get_assignee_cards(params[:user_id])
        cards_completed_by_command(tips.map(&:id))
      end
    end

    def get_cards_in_progress_by_command
      if params[:topic_id].present? && params[:user_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        tip_ids = get_tips_for_given_user(tips)
        cards_in_progress_by_command(tip_ids)
      elsif params[:topic_id].present?
        tips = get_tips_for_topic(params[:topic_id])
        cards_in_progress_by_command(tips.map(&:id))
      elsif params[:user_id].present?
        tips = get_assignee_cards(params[:user_id])
        cards_in_progress_by_command(tips.map(&:id))
      end
    end

    def get_cards_this_week_by_command
      if params[:topic_id].present? && params[:user_id].present?
      	tips = get_tips_for_topic(params[:topic_id])
      	tip_ids = get_tips_for_given_user(tips)
      	cards_this_week_by_command(tip_ids)
      elsif params[:topic_id].present?
      	tips = get_tips_for_topic(params[:topic_id])
      	cards_this_week_by_command(tips.map(&:id))
      elsif params[:user_id].present?
      	tips = get_assignee_cards(params[:user_id])
      	cards_this_week_by_command(tips.map(&:id))
      end
    end

    def get_tips_for_topic(topic_id)
      tips = pick_tips(topic_id: topic_id)
      tip_share_with_topic(topic_id, tips)
    end

    def tip_share_with_topic(topic_id, tips)
      follows = Follow.where(followable_type: "Topic", followable_id: topic_id, follower_type: "Tip")
      follows.each do |follow|
        tips << follow.follower
      end
      tips.uniq(&:id)
    end

    def over_due_card_by_command(tip_ids)
      tips = get_tips(tip_ids)
      tips = tips.where("due_date < ? AND completion_date IS ?",current_date, nil)
      render json: {title: params[:title], card_overdue_weekly: get_assign_user(tips) }, status: :ok
    end

    def cards_completed_by_command(tip_ids)
      tips = get_tips(tip_ids)
      tips = tips.where.not(completion_date: nil)
      render json: {title: params[:title], card_complete_weekly: get_assign_user(tips) }, status: :ok
    end

    def cards_in_progress_by_command(tip_ids)
      tips = get_tips(tip_ids)
      tips = tips.where("start_date < ?",current_date+1).where(completion_date: nil, completed_percentage: 1..99)
      render json: {title: params[:title], card_in_progress_weekly: get_assign_user(tips) }, status: :ok
    end

    def cards_this_week_by_command(tip_ids)
      tips = get_tips(tip_ids)
      tips = tips.where(due_date: current_date.beginning_of_week-1..current_date.end_of_week-1, completion_date: nil)
      render json: {title: params[:title], card_due_this_week: get_assign_user(tips)}, status: :ok
    end

    def get_tips(tip_ids)
    	tips = Tip.where(id: tip_ids)
    end

    def get_tips_for_given_user(tips)
      tips_for_given_user = []
      tips.each do |tip|
        tips_for_given_user << tip.id if tip.assigned_users.map(&:id).include?(params[:user_id])
      end
      tips_for_given_user
    end
  end
end
