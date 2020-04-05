module V2
  class TipsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_on_domain!
    before_action :set_paper_trail_whodunnit
    # before_action :authorize_profiler
    include TipConcern

    INCLUDED = ['share_settings', 'tip_assignments', 'topics', 'labels', 'attachments', 'subtopics', 'nested_tips']

    def index
      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1

      tips = build_tips(params)

      tips = tips.filter_tips(params[:filter], tips, params[:page].try(:[], :size), current_user) if params[:filter].present?

      tips = tips.reorder(TipSortParams.sorted_fields(params[:sort])) if params.key?(:sort)
      tips = paginate(tips)

      page_data = {
        current_page: params[:page][:number].to_i,
        count_on_page: tips.count,
        total_count:  tips.total_count,
        total_pages:  tips.total_pages
      }

      render json: TipDetailSerializer.new(
        tips,
        {
          include: INCLUDED,
          params: {
            current_user: current_user,
            topic_id: params[:topic_id],
            domain: current_domain,
          }
        }).serializable_hash.merge({
          meta: build_meta_data(page_data)
        })
    end

    def show
      tip = Tip.find_by(id: params[:id])

      authorization_check(tip, :can_read)

      redirect_to_good_slug(tip) && return if bad_slug?(tip)
      render json: TipDetailSerializer.new(
        tip, { 
          params: {
            topic_id: params[:topic_id],
            domain: current_domain,
            current_user: current_user
          },
          include: INCLUDED,
        })
    end

    def create
      tip = Tip.new(tip_params.merge user: current_user)
      tip.save

      render_errors(tip.errors.full_messages) && return if tip.errors.any?

      relationships = params['data']['relationships']
      subtopics = params['data']['relationships']['subtopics'] if relationships.present?
      tip.follow_multiple_resources(:topic, subtopics, current_user, params) if subtopics.present?

      tip.follow_tip(params['data']['relationships'].try(:[], :parent_tip))

      destroy_if_no_follows(tip)

      tip.share_with_all_relationships(params, current_user)
      
      tip.connect_attachments(params)
      tip.process_attachments_as_json
      tip.connect_labels(params)
      tip.connect_tip_assignments(params)
      tip.connect_dependency(params)
      tip.nested_connections(params)

      render json: TipDetailSerializer.new(
        tip, { params: { current_user: current_user, domain: current_domain }, include: INCLUDED }
        ), status: :created, location: [:v2, tip]
    end

    def update
      tip = Tip.find_by(id: params[:id])
      relationships = params['data']['relationships']
      @subtopics = relationships['subtopics'] if relationships.present?

      authorization_check(tip, :can_update)

      tip.update_attributes(tip_params) if params['data'].try(:[], :attributes).present?

      push_bot_notification(tip)
      tip.follow_multiple_resources(:topic, @subtopics) if @subtopics.present?
      tip.share_with_all_relationships(params, current_user)
      tip.connect_attachments(params)
      tip.process_attachments_as_json
      tip.connect_labels(params)
      tip.connect_dependency(params)
      tip.connect_tip_assignments(params)
      tip.nested_connections(params)

      render_errors(tip.errors.full_messages) && return if tip.errors.any?
      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          },
          include: INCLUDED + ['versions']
        }), status: :ok 
    end

    def destroy
      tip = Tip.find_by(id: params[:id])

      authorization_check(tip, :can_destroy)
      tip_orders = tip.topic_orders
      tip.remove_from_order(tip_orders,tip.id)

      render_errors('Could not delete Card') && return unless tip.destroy

      render json: {}, status: :no_content
    end

    def share_with_relationships
      tip = Tip.find(params[:id])

      tip.share_with_all_relationships(params)

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def flag
      tip = Tip.find(params[:id])
      tip.flag(current_user, params[:reason])

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    # TODO, Teefan: I think we should separate this into Like controller,
    #       and the method maybe extracted into a model module
    def like
      tip = Tip.find(params[:id])
      authorization_check(tip, :can_like)
      VoteService.add_vote(current_user, tip, :like)

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def unlike
      tip = Tip.find(params[:id])
      authorization_check(tip, :can_like)
      VoteService.remove_vote(current_user, tip, :like)

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def star
      tip = Tip.find(params[:id])
      VoteService.add_vote(current_user, tip, :star)

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def unstar
      tip = Tip.find(params[:id])
      VoteService.remove_vote(current_user, tip, :star)

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    # TODO, Teefan: I think we should separate this into Vote controller,
    #       and the method maybe extracted into a model module
    def upvote
      tip = Tip.find(params[:id])
      tip.vote_by voter: current_user

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def downvote
      tip = Tip.find(params[:id])
      tip.downvote_from current_user

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    # Receives paylod { topic_id: '', preceding_tips: [], context_id: '' }
    def reorder
      render_errors('You must be in a topic') && return unless reorder_params[:topic_id]

      tip = Tip.find(params[:id])
      render_errors('Card not found') && return unless tip

      reorder_results = ReorderService.new(
        user: current_user,
        domain: current_domain,
        resource: tip,
        topic_id: reorder_params[:topic_id],
        context_id: reorder_params[:context_id],
        preceding_resources: reorder_params[:preceding_tips],
        tip_id: reorder_params[:parent_tip]
      )

      reorder_results.reorder

      render_errors(reorder_results.errors) && return if reorder_results.errors.any?

      tip.position = reorder_results.new_resource_position

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def archive
      tip = Tip.find(params[:id])
      authorization_check(tip, :can_destroy)

      tip.archive! unless tip.is_disabled?

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    def unarchive
      tip = Tip.find(params[:id])
      tip.unarchive if tip.is_disabled?

      render json: TipDetailSerializer.new(
        tip,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), status: :ok, location: [:v2, tip]
    end

    # Find tips assigned to selected users
    def assigned_to
      assigned_tips = Tip.joins(:assigned_users).where(tip_assignments: {assignment_id: params[:user_ids]})
      viewable_tips = current_user.viewable_tips
      # find repeating tips in both arrays
      tips = assigned_tips & viewable_tips

      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1
      tips = paginate(tips)

      page_data = {
        current_page: params[:page][:number].to_i,
        count_on_page: tips.count,
        total_count:  tips.total_count,
        total_pages:  tips.total_pages
      }

      render json: TipDetailSerializer.new(
        tips,
        {
          params: {
            current_user: current_user,
            domain: current_domain
          }
        }
      ), meta: build_meta_data(page_data)
    end

    def fetch_versions
      tip = Tip.find_by(id: params[:id])

      authorization_check(tip, :can_read)
      redirect_to_good_slug(tip) && return if bad_slug?(tip)
      render json: TipVersionSerializer.new(
        PaperTrail::Version.where(
          item_id: params[:id],
          event: "update", item_type: "Tip"
          ).where.not(object: nil).order(created_at: :desc)
        )
    end

    private

    def tip_params
      params.require(:data)
        .require(:attributes)
        .permit(
          :title,
          :body,
          :user_followers,
          :topics,
          :relationships,
          :share_following,
          :share_public,
          :expiration_date,
          :start_date,
          :due_date,
          :completion_date,
          :completed_percentage,
          :work_estimation,
          :resource_required,
          :expected_completion_date,
          :priority_level,
          :value,
          :effort,
          :actual_work,
          :confidence_range,
          :resource_expended
        )
    end

    def reorder_params
      params.require(:data).permit(:topic_id, :context_id, :parent_tip, preceding_tips: [])
    end

    def flag_params
      params.require(:data).permit(:reason)
    end

    def authorization_check(tip, action)
      return true if action == :can_read && current_domain.tenant_name == 'support'
      fail CanCan::AccessDenied unless tip
      # TODO: Temporary solution until we integrate viewable into permissions
      # AND have tip level permissions, currently, it relies on Topic permissions
      fail CanCan::AccessDenied if action == :can_read && !tip.viewable_by?(current_user)

      fail CanCan::AccessDenied unless tip.abilities(current_user)[:self][action]
    end

    def destroy_if_no_follows(tip)
      return if tip.follows.any?

      tip.destroy

      fail CanCan::AccessDenied
    end

    def build_tips(params)
      tips = pick_tips(params)

      tips.includes(:roles).filter(filter_as_nested_resource(params))
    end

    def push_bot_notification(tip)
      activity_channel = "#{current_domain.tenant_name}-activities"
      bot_notification = set_bot_notification(tip)
      Pusher.trigger(activity_channel, "bot-notification", notification: bot_notification) rescue nil
    end

    def set_bot_notification(tip)
      { card_overdue: tip.due_date.try(:to_date) == current_date && tip.completion_date == nil ? serialize_bot_data(tip) : [],
        card_complete: tip.completion_date.try(:to_date) == current_date ? serialize_bot_data(tip) : [],
        card_at_risk: tip.due_date.present? && tip.due_date.try(:to_date) < current_date-2 && tip.completed_percentage == 0 ? serialize_bot_data(tip) : [],
        card_started: tip.start_date.try(:to_date) == current_date ? serialize_bot_data(tip) : [],
        live_notification: true
      }
    end

    def serialize_bot_data(tip)
      data = {}
      data["assignee"] = tip.assigned_users.map(&:first_name)
      data["title"] = tip.title
      data["id"] = tip.id
      data["updated_at"] = tip.updated_at
      data
    end

  end
end
