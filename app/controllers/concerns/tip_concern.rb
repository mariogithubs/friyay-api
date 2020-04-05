module TipConcern
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/PerceivedComplexity
  def pick_tips(params)
    return support_tips(params) if current_domain.tenant_name == 'support'

    # REFACTOR: Move this to Tip model or a service
    context_id = "user:#{current_user.id}"
    context_id += ":domain:#{current_domain.id}" if current_domain.id

    context_id = params[:context_id] || context_id
    context = Context.find_by(context_uniq_id: context_id) || nil

    if params[:topic_id]
      # We're on a Topic
      context_id += ":topic:#{params[:topic_id]}" unless context_id.include?('topic')

      # Use default if there is one
      context = Context.current_or_default(context_id)
      topic = Topic.find(params[:topic_id])

      # context is only used for ordering, not filtering tips
      tips = topic.viewable_tips_for(current_user, context: context, view_id: params[:view_id])
    elsif params[:user_id]
      # We're on a user profile
      creator = User.find(params[:user_id])
      tips = current_user.viewable_tips_from(creator, context)
    else
      # TODO: Optimize serializer so that fewer database calls are made
      tips = current_user.viewable_tips(context: context)
    end

    return tips.enabled unless archive_label_present?

    tips
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def support_tips(params)
    if params[:topic_id]
      topic = Topic.find(params[:topic_id])

      return topic.tip_followers.public_tips.enabled
    end

    Tip.public_tips.enabled
  end

  def archive_label_present?
    filter_labels = params[:filter] && params[:filter][:labels]
    return false if filter_labels.blank?

    filter_labels = filter_labels.split(',') if filter_labels.is_a?(String)
    filter_labels.include?(Label.archived.id.to_s)
  end
end