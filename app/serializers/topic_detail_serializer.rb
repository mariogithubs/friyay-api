class TopicDetailSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :user_id, :show_tips_on_parent_topic, :created_at, :path,
             :kind, :starred_by_current_user, :tip_count, :default_view_id, :image, :cards_hidden,
             :parent_id, :is_secret, :apply_to_all_childrens, :ancestry

  has_many :topic_preferences
  has_many :share_settings

  has_one  :topic_permission
  has_many :roles

  has_many :abilities
  has_many :masks
  has_many :topic_orders
  belongs_to :label_order
  belongs_to :people_order

  # TODO: this should return a list of contexts
  # with { name: name, context_id: context.id }
  has_many :contexts

  def parent_id
    object.ancestry.nil? ? nil : object.ancestry.split('/')[-1]
  end

  def topic_permission
    build_topic_permission_json(object.topic_permission)
  end

  def path
    object.path.collect do |topic|
      build_ancestor(topic)
    end
  end

  def topic_preferences
    topic_preferences = set_topic_preferences

    topic_preferences.collect do |topic_preference|
      build_preference_json(topic_preference) if topic_preference
    end
  end

  def tips
    tips = object.tip_followers
    
  end

  def share_settings
    build_share_settings(object.share_settings.where(:sharing_object_type => ['User','Group']))
  end

  def kind
    object.subtopic? ? 'Subtopic' : 'Hive'
  end

  def starred_by_current_user
    scope.voted_for?(object, vote_scope: :star)
  end

  def tip_count
    object.tip_followers.enabled.count
  end

  private

  def build_share_settings(settings)
    share_array = settings.collect do |share_setting|
      build_share_setting(share_setting) if share_setting
    end

    return [{
      sharing_object_id: 'private',
      sharing_object_type: 'users',
      sharing_object_name: 'Just Me (Private)'
    }] if private?

    share_array.compact + build_follower_overrides
  end

  def build_ancestor(topic)
    return nil if topic.blank?

    {
      id: topic.id.to_s,
      type: 'topics',
      title: topic.title,
      slug: topic.slug
    }
  end

  def set_topic_preferences
    return [object.topic_preferences.first] if scope.blank?

    topic_preferences = object.topic_preferences.where(user_id: scope.id)

    return [object.topic_preferences.first] if topic_preferences.blank?

    topic_preferences
  end

  def build_preference_json(topic_preference)
    {
      id: topic_preference.id,
      user_id: topic_preference.user_id,
      type: topic_preference.class.model_name.plural,
      background_color_index: topic_preference.background_color_index,
      background_image_url: topic_preference.background_image.large.url,
      share_following: topic_preference.share_following,
      share_public: topic_preference.share_public,
      link_option: topic_preference.link_option,
      link_password: topic_preference.link_password
    }
  end

  def build_share_setting(share_setting)
    resource = share_setting.sharing_object
    return nil if resource.blank?

    sharing_object_type = share_setting.sharing_object_type.downcase.pluralize

    {
      id: share_setting.id,
      sharing_object_id: share_setting.sharing_object_id,
      sharing_object_type: sharing_object_type,
      sharing_object_name: (resource.try(:name) || resource.title),
      shareable_object_avatar: (resource.avatar.try(:url) if resource.respond_to?(:avatar))
    }
  end

  def build_follower_overrides
    override_array = []
    override_array << everyone_object if object.topic_preferences.for_user(scope).share_public?
    override_array << following_object if object.topic_preferences.for_user(scope).share_following?

    override_array
  end

  def private?
    object.topic_preferences.for_user(scope).private?
  end

  def everyone_object
    sharing_object_name = current_domain.public_domain? ? 'Public' : 'All Team Workspace members' 
    { sharing_object_id: 'everyone', sharing_object_type: 'users', sharing_object_name: sharing_object_name }  
  end

  def following_object
    { sharing_object_id: 'following', sharing_object_type: 'users', sharing_object_name: 'People I Follow' }
  end

  def roles
    build_roles_json(object.users_roles)
  end

  def masks
    object.masks(scope)
  end

  def abilities
    object.abilities(scope)
  end

  def build_topic_permission_json(topic_permission)
    {
      id: topic_permission.try(:id),
      access_hash: topic_permission.try(:access_hash) || {},
      domain_access_hash: current_domain.permission
    }
  end

  def build_roles_json(users_roles)
    users_roles.collect do |users_role|
      {
        name: Role.find_by(id: users_role.role_id).try(:name),
        user_id: users_role.user_id,
        user_name: User.find_by(id: users_role.user_id).try(:name)
      }
    end
  end

  def current_domain
    Domain.find_by(tenant_name: Apartment::Tenant.current) || Domain.new(tenant_name: 'public', join_type: 'open')
  end
end
