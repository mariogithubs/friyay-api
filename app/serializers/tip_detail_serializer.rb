class TipDetailSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :body, :slug, :color_index, :created_at, :updated_at,
             :likes_count, :comments_count, :expiration_date, :is_disabled, :share_public,
             :share_following, :roles, :attachments_json, :position, :start_date, :due_date,
             :completion_date, :completed_percentage, :work_estimation, :resource_required,
             :expected_completion_date, :priority_level, :value, :effort, :actual_work,
             :confidence_range, :resource_expended, :is_secret

  attribute :private do |object|
    object.private?
  end
  
  belongs_to :user, serializer: UserSmallSerializer

  # TODO: Optimize these by defining them below and user .includes or something
  # TODO: Paginate associations somehow??
  has_many :topics, serializer: IncludedTopicSerializer, &:following_topics

  has_many :subtopics, serializer: IncludedTopicSerializer, &:subtopics
  
  has_many :share_settings, serializer: ShareSettingSerializer, &:share_settings
  
  attribute :abilities do |object, params|
    object.abilities(params[:current_user])
  end
  
  attribute :masks do |object, params|
    object.masks(params[:current_user])
  end
  
  has_many :labels, &:labels_for
  
  has_many :nested_tips, serializer: TipDetailSerializer, &:nested_tips
  
  has_many :depends_on
  has_many :depended_on_by

  has_many :tip_assignments, serializer: TipAssignmentSerializer, &:tip_assignments

  has_many :follows_tip, &:follows_tip
  
  has_many :attachments, serializer: IncludedAttachmentSerializer, &:attachments
  has_many :versions, serializer: TipVersionSerializer, object_method_name: :versions_with_data
  
  attribute :creator do |object|
    object.user_id.blank? || !User.exists?(object.user_id) ? {} : build_user_json(object.user)
  end

  attribute :liked_by_current_user do |object, params|
    params[:current_user].voted_for? object, vote_scope: :like
  end

  attribute :starred_by_current_user do |object, params|
    params[:current_user].voted_for?(object, vote_scope: :star)
  end

  def self.build_user_json(user)
    profile = user.user_profile
    {
      id: user.id.to_s,
      type: user.class.model_name.plural,
      name: "#{user.first_name} #{user.last_name}",
      avatar_url: profile.avatar_thumbnail_url,
      url: Rails.application.routes.url_helpers.v2_user_url(user, host: 'api.tiphive.dev')
    }
  end

end
