# == Schema Information
#
# Table name: topics
#
#  id                        :integer          not null, primary key, indexed
#  title                     :string           not null, indexed => [ancestry]
#  description               :text
#  user_id                   :integer          not null, indexed
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  ancestry                  :string           indexed, indexed => [title]
#  old_subtopic_id           :integer
#  default_view_id           :string
#  image                     :string
#  is_deleted                :boolean          default(FALSE)
#  is_disabled               :boolean          default(FALSE)
#  label_order_id            :integer          indexed
#  people_order_id           :integer          indexed
#  show_tips_on_parent_topic :boolean          default(TRUE)
#  cards_hidden              :boolean
#  is_secret                 :boolean          default(FALSE)
#  apply_to_all_childrens    :boolean          default(FALSE)
#

class Topic < ActiveRecord::Base
  resourcify

  include Adminify
  include Slugger
  include Connectable::Model
  include Filterable
  include Shareable
  include Join::Topic
  include Permission::Topic

  acts_as_followable
  has_paper_trail
  acts_as_votable

  attr_accessor :position

  has_many :topic_preferences, autosave: true, dependent: :destroy
  has_many :topic_users
  belongs_to :user
  has_many :users_roles, through: :roles, source: :roles_users

  has_one :topic_permission, as: :permissible, dependent: :destroy
  accepts_nested_attributes_for :topic_permission, allow_destroy: true

  has_many :invitations, as: :invitable
  has_many :contexts
  has_many :context_topics

  has_many :topic_orders
  has_many :user_topic_label_order, dependent: :destroy
  has_many :label_orders, :through => :user_topic_label_order
  has_many :user_topic_people_order, dependent: :destroy
  has_many :people_orders, :through => :user_topic_people_order
  belongs_to :label_order
  belongs_to :people_order

  has_and_belongs_to_many :sub_topic_orders, class_name: "TopicOrder", 
                                     join_table: "topic_orders_topics"

  has_ancestry

  delegate :preferences, to: :topic_preferences

  validates :title, presence: true
  # validates :title, topic_title: true, if: :is_root?
  validates :title, uniqueness: { scope: :ancestry }

  after_create :share_topic_with_creator

  mount_uploader :image, ImageUploader
  
  scope :sort, -> (sort_params) { order(sort_params || { created_at: :desc }) }
  scope :user, -> (user) { where(user: user) }
  scope :with_root, -> { where.not(ancestry: nil) }
  scope :without_root, -> { where(ancestry: nil) }

  searchable do
    text :title, :description
    string :kind do
      self.class.name
    end
    integer :user_id
    string :tenant_name do
      Apartment::Tenant.current
    end
    # boolean :is_public, :is_on_profile, :allow_add_pocket, :allow_friend_share
    # string :sharing_type
  end

  def parent_id
    ancestry.nil? ? nil : ancestry.split('/')[-1]
  end

  def subtopic?
    ancestry.present?
  end

  def serialize
    ActiveModel::SerializableResource.new(self).serializable_hash
  end

  def viewable_tips_for(user, context: nil, view_id: nil)
    # return Tip.for_topic(self).enabled unless user.following?(self)
    show_tips_in_subtopics = View.find_by(id: view_id).try(:show_nested_tips)

    topic_ids = [id]
    topic_ids += descendants.pluck(:id) unless show_tips_in_subtopics == false

    follow_count = Follow.select(:id).where(
      followable_type: 'Topic',
      follower_type: 'Tip',
      followable_id: topic_ids
    ).count

    return Tip.none if follow_count == 0
    topic_preferences.for_user(user).viewable_tips(context: context, topic_ids: topic_ids)
  end

  def default_preferences
    topic_preferences.find_by(user_id: user_id, topic_id: id)
  end

  def invite_url
    "/hives/#{id}"
  end

  def ensure_topic_preference_for(user)
    topic_preferences.for_user(user)
  end

  def self.roots_for(subtopics)
    # This is faster than subtopics.map(&:root)
    return [] if subtopics.compact.empty?

    where(id: subtopics.map { |subtopic| subtopic.ancestry.split('/').first })
  end

  def remove(params, cuser)
    params ||= {}
    hive_name = title
    new_topic = Topic.find_by(id: params['alternate_topic_id'])

    if new_topic
      children.each { |subtopic| subtopic.update_attributes!(parent: new_topic) }

      tip_followers.each do |tip|
        tip.stop_following(self)
        tip.follow(new_topic)
      end
    else
      recursive_tip_list.each(&:archive!)
      descendants.each(&:destroy)
    end

    user_ids_to_notify = user_followers.ids - [user.id]

    return unless destroy

    notify_followers_destroy(
      cuser,
      removed_hive_title: hive_name,
      user_ids: user_ids_to_notify,
      alternate_hive_id: params['alternate_topic_id']
    ) # if params['notify'] -- DEFAULT set 4/14/2016
  end

  def notify_followers_destroy(notifier, opts)
    NotificationWorker.perform_in(
      10.seconds,
      'hive_removed',
      notifier.id,
      'User',
      opts
    )
  end

  def recursive_tip_list
    tip_collection = []
    tip_collection << tip_followers
    descendants.each { |subtopic| tip_collection << subtopic.tip_followers }

    tip_collection.flatten!
    tip_collection.uniq!

    tip_collection
  end

  def move(alternate_topic)
    disconnect_descendant_tips_from_ancestors
    disconnect_tip_followers_from_ancestors # disconnects own tip_followers

    update_attribute(:parent_id, nil) if alternate_topic.blank?
    return true if alternate_topic.blank?

    update_attribute :parent_id, alternate_topic.id
  end

  def updatable_by?(cuser)
    return false if cuser.cannot? :update, self

    can_access = true

    tip_followers.each do |tip|
      next unless can_access
      can_access = false if cuser.cannot? :update, tip
    end

    can_access
  end

  def permission
    topic_permission.try(:access_hash) || {}
  end

  def remove_from_order(topic_orders, id)
    topic_orders.each do |order|
      new_order = (order.subtopic_order -= [id.to_s])
      order.update(:subtopic_order => new_order) 
    end  
  end

  def update_label_order(params)
    label_order = params.try(:[], 'data').try(:[], 'relationships')
                  .try(:[], 'label_order').try(:[], 'data')
    return unless label_order
    self.update(label_order_id: label_order[:id])
  end

  def update_people_order(params)
    people_order = params.try(:[], 'data').try(:[], 'relationships')
                  .try(:[], 'people_order').try(:[], 'data')
    return unless people_order
    self.update(people_order_id: people_order[:id])
  end

  def self.order_by_ids(ids)
    return unless ids.present?
    topics_ids = ids.split(",")
    order_by = ["CASE"]
    topics_ids.each_with_index do |id, index|
      order_by << "WHEN topics.id='#{id}' THEN #{index}"
    end
    order_by << "END"
    select(order_by.join(" ")).reorder(order_by.join(" "))
  end  

  private

  def disconnect_descendant_tips_from_ancestors
    descendants.each do |descendant|
      disconnect_tip_followers_from_ancestors(descendant)
    end
  end

  def disconnect_tip_followers_from_ancestors(topic = self)
    tips = topic.tip_followers

    topic.ancestors.each do |ancestor_topic|
      tips.each { |tip| tip.stop_following(ancestor_topic) }
    end
  end
end
