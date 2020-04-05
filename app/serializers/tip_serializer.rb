
class TipSerializer
  include FastJsonapi::ObjectSerializer

  set_type :tips
  
  attributes :title, :body, :slug, :color_index, :created_at, :updated_at,
             :likes_count, :comments_count,
             :starred_by_current_user, :expiration_date, :is_disabled, :share_public,
             :share_following, :roles, :attachments_json, :start_date, :due_date, 
             :completion_date, :completed_percentage, :work_estimation, :resource_required,
             :expected_completion_date, :priority_level, :value, :effort, :actual_work, :confidence_range, :resource_expended, :is_secret

  # belongs_to :user

  # TODO: Optimize these by defining them below and user .includes or something
  # TODO: Paginate associations somehow??
  has_many :topics, &:following_topics

  has_many :subtopics, &:subtopics
  # do |object|
  #   subtopic_list = object.subtopics.collect do |subtopic|
  #     build_topic_json(subtopic)
  #   end
  #   subtopic_list.sort_by { |subtopic| subtopic[:hive] }
  # end
  
  attribute :abilities do |object, params|
    object.abilities(params[:current_user])
  end

  attribute :masks do |object, params|
    object.masks(params[:current_user])
  end
  
  has_many :labels, &:labels_for
  
  has_many :nested_tips, &:nested_tips
  
  has_many :attachments, &:attachments

  attribute :creator do |object|
    return {} if object.user_id.blank?
    return {} unless User.exists?(object.user_id)
    build_user_json(object.user)
  end

  attribute :liked_by_current_user do |object, params|
    params[:current_user].voted_for?(object, vote_scope: :like)
  end

  attribute :starred_by_current_user do |object, params|
    params[:current_user].voted_for?(object, vote_scope: :star)
  end

  def self.build_user_json(user)
    profile = user.user_profile
    {
      id:         user.id.to_s,
      name:       "#{user.first_name} #{user.last_name}",
      avatar_url: profile.avatar_thumbnail_url
    }
  end

end
