# == Schema Information
#
# Table name: tips
#
#  id                                  :integer          not null, primary key, indexed
#  user_id                             :integer          not null, indexed
#  title                               :string           indexed
#  body                                :text
#  color_index                         :integer
#  access_key                          :string           indexed
#  share_public                        :boolean          default(TRUE), not null
#  share_following                     :boolean          default(FALSE), not null
#  properties                          :hstore
#  statistics                          :hstore
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  expiration_date                     :datetime
#  is_disabled                         :boolean          default(FALSE)
#  cached_scoped_like_votes_total      :integer          default(0), indexed
#  cached_scoped_like_votes_score      :integer          default(0), indexed
#  cached_scoped_like_votes_up         :integer          default(0), indexed
#  cached_scoped_like_votes_down       :integer          default(0), indexed
#  cached_scoped_like_weighted_score   :integer          default(0), indexed
#  cached_scoped_like_weighted_total   :integer          default(0), indexed
#  cached_scoped_like_weighted_average :float            default(0.0), indexed
#  attachments_json                    :jsonb            default({}), not null, indexed
#  start_date                          :datetime
#  due_date                            :datetime
#  completion_date                     :datetime
#  completed_percentage                :integer          default(0)
#  work_estimation                     :integer
#  resource_required                   :decimal(, )
#  expected_completion_date            :datetime
#  is_deleted                          :boolean          default(FALSE)
#  priority_level                      :string
#  value                               :integer
#  effort                              :integer
#  actual_work                         :integer
#  confidence_range                    :integer
#  resource_expended                   :decimal(, )
#  is_secret                           :boolean          default(FALSE)
#

class Tip < ActiveRecord::Base
  include Parse
  include Adminify
  include Perishable

  resourcify

  include ActsAsFlaggable
  include Slugger
  include Connectable::Model
  include Filterable
  include Shareable
  include Permission::Tip
  include AttachmentParser

  acts_as_follower
  acts_as_followable
  acts_as_commentable
  acts_as_votable

  has_paper_trail only: [
    :user_id,
    :title,
    :body,
    :attachments_json,
    :expiration_date,
    :is_disabled,
    :start_date,
    :due_date,
    :completion_date,
    :completed_percentage,
    :work_estimation
  ], on: [:update]

  has_many :versions,
    -> { order("id desc") },
    class_name: 'PaperTrail::Version',
    as: :item

  attr_accessor :position

  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :commenters, source: :user, foreign_key: :user_id, through: :comment_threads
  has_many :tip_links, dependent: :destroy
  has_many :invitations, as: :invitable

  has_many :label_assignments, -> { where(item_type: 'Tip') }, foreign_key: :item_id
  has_many :labels, -> { where(label_assignments: { item_type: 'Tip' }) },
           through: :label_assignments,
           foreign_key: :item_id
  has_many :tip_assignments
  has_many :assigned_users, through: :tip_assignments, source: :assignment,
           :source_type => "User"
  has_many :assigned_groups, through: :tip_assignments, source: :assignment,
           :source_type => "Group"

  has_many :context_tips

  has_and_belongs_to_many :depends_on, class_name: "Tip",
                                     join_table: "tips_dependencies",
                                     foreign_key: "depended_on_by",
                                     association_foreign_key: "depends_on"
  has_and_belongs_to_many :depended_on_by, class_name: "Tip",
                                     join_table: "tips_dependencies",
                                     foreign_key: "depends_on",
                                     association_foreign_key: "depended_on_by"

  has_and_belongs_to_many :topic_orders, join_table: "topic_orders_tips"
  belongs_to :user

  ##################################################
  # VALIDATIONS
  ##################################################
  # validates_inclusion_of :value, :in => 1..10
  # validates_inclusion_of :effort, :in => 1..10

  validates :user, presence: true

  validate :due_after_start

  before_validation :generate_tip_color
  after_create :share_with_creator

  ##################################################
  # SCOPES
  ##################################################
  scope :sort, -> (sort_params) { order(sort_params || { created_at: :desc }) }
  scope :join_followables, -> { joins(build_join_string 'followable') }
  scope :join_followers, -> { joins(build_join_string 'follower') }
  scope :public_tips, -> { where(share_public: true) } # NOT TESTED
  scope :for_topic, -> (topic) { where(id: topic.followings.where(follower_type: 'Tip').pluck(:follower_id)) }
  scope :enabled, -> { where(is_disabled: false) }
  scope :archived, -> { where(is_disabled: true) }

  enum priority_level: { Highest: 'Highest', High: 'High', Medium: 'Medium', Low: 'Low', Lowest: 'Lowest'}

  searchable do
    text :title
    string :kind do
      self.class.name
    end
    text :body

    # TODO: but does this re-index when a tip follows or stops following?
    # integer :topic_id, multiple: true do
    #   following_topics.map(&:id)
    # end

    string :tenant_name do
      Apartment::Tenant.current
    end
    integer :user_id
    boolean :share_public
  end

  def labels_for(params)
    labels.where("kind IN ('public', 'system') OR (kind = 'private' AND user_id = ?)", params[:current_user].id)
  end

  def topics
    x = (following_topics.without_root + Topic.roots_for(subtopics({})))
    x.uniq
  end

  def subtopics(params)
    following_topics.with_root
  end

  def notify_like(like)
    NotificationWorker.perform_in(1.second, 'someone_likes_tip', like.id, like.class.to_s)
  end

  def move_or_remove(topic, cuser, alternate_topic = nil)
    follow(alternate_topic) if alternate_topic
    return if cuser.cannot? :destroy, self
    return if (topics - [topic]).present?

    # This may become archive, or we may have an option parameter
    # The signature of this method may change to move_or_remove(opts)
    # where opts = { topic: topic, cuser: user, alt_topic: topic or nil, archive: true/false }
    destroy
  end

  def likes_count
    cached_scoped_like_votes_up
  end

  def comments_count
    comment_threads.count
  end

  def follows_tip(params)
    if self.follows.where(:followable_type => "Tip").present?
      self.follows.where(:followable_type => "Tip").first.followable
    end  
  end

  def private?
    return false if share_public == true
    return false if share_following == true
    return false if (user_followers - [user]).any?
    return false if group_followers.any?

    true
  end

  def viewable_by?(viewer)
    return true if user_id == viewer.id
    return true if share_public == true && viewer.member_of?(current_domain)
    return true if share_public == true && viewer.power_of?(current_domain)

    viewer.viewable_tips.include?(self)
  end

  def tip_followers_in_order(args)
    context_id = Context.generate_id(
      user: args[:user_id],
      domain: args[:domain_id],
      topic: args[:topic_id],
      tip: args[:tip_id]
    )

    context_join = 'LEFT JOIN context_tips ON context_tips.tip_id = tips.id'
    context_join += " AND context_tips.context_id = '#{context_id}'"

    tip_followers.joins(context_join)
      .order('context_tips.position')
      .order(created_at: 'DESC')
  end

  def remove_from_order(topic_orders, id)
    topic_orders.each do |order|
      new_order = (order.tip_order -= [id.to_s])
      order.update(:tip_order => new_order)
    end
  end

  def self.order_by_ids(ids)
    return if ids.blank?
    tips_ids = ids.split(",")
    order_by = ["CASE"]
    tips_ids.each_with_index do |id, index|
      order_by << "WHEN tips.id='#{id}' THEN #{index}"
    end
    order_by << "END"
    reorder(order_by.join(" "))
  end

  def nested_connections(params)
    follows_tip = params.try(:[], 'data').try(:[], 'relationships')
                  .try(:[], 'follows_tip').try(:[], 'data')

    self.follows.where(:followable_type => "Tip").destroy_all && return unless follows_tip

    if self.follows.where(:followable_type => "Tip").present?
      self.follows.where(:followable_type => "Tip").destroy_all
    end

    self.follow(Tip.find_by_id(follows_tip[:id]))
  end

  def nested_tips(params)
    self.tip_followers_in_order(
      user_id: params[:current_user].try(:id),
      domain_id: params[:domain].try(:id),
      topic_id: params[:topic_id].try(:split, "-").try(:first),
      tip_id: self.id
    )
  end

  def user_followers_list(params)
    self.user_followers.includes([:user_profile]) - [params[:current_user]]
  end


  def versions_with_data
    self.versions.where.not(object: nil)
  end

  private

  def generate_tip_color
    self.color_index = rand(1..7)
  end

  def self.build_join_string(kind)
    kind_type = 'follows.followable_type' if kind == 'followable'
    kind_type = 'follows.follower_type' if kind == 'follower'

    kind_id = 'follows.followable_id' if kind == 'followable'
    kind_id = 'follows.follower_id' if kind == 'follower'

    string = "LEFT JOIN follows ON #{kind_type} = 'Tip'"
    string += " and #{kind_id} = tips.id"

    string
  end

  # Custom validation to make sure the due date is later than or equal to the start date
  def due_after_start
    return if due_date.blank? || start_date.blank?
    return true if due_date >= start_date

    errors.add(:due_date, 'must be later than or equal to the start date')
  end
end
