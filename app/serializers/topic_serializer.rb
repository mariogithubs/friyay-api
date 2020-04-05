class TopicSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :user_id, :show_tips_on_parent_topic, :created_at, :path, :parent_user,
             :parent_label_order, :parent_people_order, :kind, :ancestry,
             :starred_by_current_user, :tip_count, :default_view_id, :cards_hidden, :is_secret, :apply_to_all_childrens

  def path
    object.path.collect do |topic|
      build_ancestor(topic)
    end
  end

  def kind
    object.subtopic? ? 'Subtopic' : 'Hive'
  end

  def starred_by_current_user
    return false unless scope
    scope.voted_for?(object, vote_scope: :star)
  end

  def tip_count
    object.tip_followers.enabled.count
  end

  def parent_user
    user = object.user
    user ? {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      created_at: user.created_at,
    } : {}
  end

  def parent_label_order
    object.label_order.present? ? get_order(object.label_order) : nil
  end

  def parent_people_order
    object.people_order.present? ? get_order(object.people_order) : nil
  end

  private

  def build_ancestor(topic)
    return nil if topic.blank?

    {
      id: topic.id,
      type: 'topics',
      title: topic.title,
      slug: topic.slug
    }
  end

  def get_order(order)
    {
      id: order.id,
      name: order.name,
      order: order.order
    }
  end
end
