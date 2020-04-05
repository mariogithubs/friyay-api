class ReorderService
  attr_accessor :user, :domain, :resource, :topic_id, :tip_id, :context_id, :preceding_resources
  attr_accessor :errors, :new_resource_position

  def initialize(args)
    @user = args[:user]
    @domain = args[:domain]
    @resource = args[:resource]
    @topic_id = args[:topic_id]
    @tip_id = args[:tip_id]
    @context_id ||= build_context_id args[:context_id]
    @preceding_resources ||= build_preceding_resources args[:preceding_resources]
    @new_resource_position = 0
    @errors = []
  end

  def reorder
    @new_resource_position = preceding_resources.count + 1
    context = create_or_find_context
    return self if context.blank?

    preceding_resources.each_with_index do |resource_id, index|
      pre_resource = resource.class.find(resource_id)
      context.reorder(pre_resource, index + 1)
    end

    context.reorder(resource, new_resource_position)

    self
  end

  private

  def build_preceding_resources(preceding_resources)
    preceding_resources || []
  end

  def build_context_id(context_id_string)
    return context_id_string if context_id_string.present?

    Context.generate_id(
      user: user.id,
      domain: domain.id,
      topic: topic_id,
      tip: tip_id
    )
  end

  def create_or_find_context
    context = Context.find_by(context_uniq_id: context_id)

    if context.blank?
      user_id = context_id.split(':')[1].to_i

      if user_id != user.id
        errors << 'You cannot create a custom order for another user'
        return
      end

      context = Context.create(
        context_uniq_id: context_id,
        name: user.name,
        default: true
      )
    end

    context
  end
end
