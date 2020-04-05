# rubocop:disable Metrics/ClassLength
module V2
  class TopicsController < ApplicationController
    before_action :authenticate_user!, except: [:suggested_topics], unless: :check_topic_preference
    # before_action :authorize_profiler
    before_action :authorize_on_domain!, except: [:suggested_topics],  unless: :check_topic_preference
    before_action :load_topic, only: [:show, :update, :destroy, :move]

    serialization_scope :find_user

    def index
      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1

      topics = build_topics(params)
      page_data = {
        current_page: params[:page][:number].to_i,
        count_on_page: topics.count,
        total_count:  topics.total_count,
        total_pages:  topics.total_pages
      }

      if params[:with_permissions].present?
        render json: topics, meta: build_meta_data(page_data), each_serializer: TopicWithPermissionsSerializer
      elsif params[:with_followers].present?
        render json: topics, meta: build_meta_data(page_data), each_serializer: TopicWithFollowersSerializer
      elsif params[:with_details].present?
        render json: topics, meta: build_meta_data(page_data), each_serializer: TopicDetailSerializer
      else
        render json: topics, meta: build_meta_data(page_data)
      end
    end

    def show
      authorize! :read, @topic unless current_user.nil?

      redirect_to_good_slug(@topic) && return if bad_slug?(@topic)

      render json: @topic, include: params[:include], serializer: TopicDetailSerializer
    end

    def create # rubocop:disable PerceivedComplexity
      authorize! :create, Topic

      # TODO: Refactor this to a method that checks the type for every resource
      render_errors('Wrong Type') && return unless %w(topics topic).include? topic_params[:type]

      @topic = new_or_existing_topic(topic_params)

      # Client requests to join Topic if it's existed
      if topic_params[:join_if_existed].present?
        @topic.save if @topic.new_record?
        current_user.follow(@topic)
        current_user.follow_tips_from_users(@topic, @topic.user_followers - [current_user])
      end

      render_conflicting_topic && return unless @topic.new_record?

      load_topic_permission

      @topic.save

      render_errors(@topic.errors.full_messages) && return if @topic.errors.any?

      # TODO: Check if topic prefs are not being created/saved
      create_default_topic_preferences(@topic, topic_params)

      @topic.share_with_all_relationships(params, current_user)

      # Pusher.trigger('topics', 'create', topic.serialize)

      load_roles

      render json: @topic, status: :created, location: [:v2, @topic], serializer: TopicDetailSerializer
    end

    def render_conflicting_topic
      render json: @topic, meta: { message: 'Topic exists, taking you there...' },
             status: :ok, location: [:v2, @topic], serializer: TopicDetailSerializer
    end

    def update
      # TODO: ENSURE ID FROM JSON MATCHES PARAMS[ID]
      render_errors('Wrong Type') && return unless %w(topics topic).include? topic_params[:type]

      authorize! :update, @topic
      
      attributes = Hash[topic_params[:attributes].map {|key, val| key == 'parent_id' && val.to_i == 0 ? [key, nil] : [key, val] }]

      @topic.attributes = attributes

      load_topic_permission

      @topic.save
      update_topic_preferences(@topic, topic_params)

      render_errors(topic.errors.full_messages) && return if @topic.errors.any?

      @topic.share_with_all_relationships(params, current_user)

      @topic.update_label_order(params)
      @topic.update_people_order(params)

      load_roles

      render json: @topic, status: :ok, location: [:v2, @topic], serializer: TopicDetailSerializer
    end

    def move
      alternate_topic = Topic.find_by(id: params[:data][:alternate_topic_id])

      authorize! :update, @topic

      render_errors('Could not move topic') && return unless @topic.move(alternate_topic)

      render json: @topic, status: :ok, location: [:v2, @topic], serializer: TopicDetailSerializer
    end

    def reorder
      topic = Topic.find(params[:id])
      render_errors('Topic not found') && return unless topic

      reorder_results = ReorderService.new(
        user: current_user,
        domain: current_domain,
        resource: topic,
        topic_id: reorder_params[:topic_id],
        context_id: reorder_params[:context_id],
        preceding_resources: reorder_params[:preceding_topics]
      )

      reorder_results.reorder
      render_errors(reorder_results.errors) && return if reorder_results.errors.any?

      topic.position = reorder_results.new_resource_position

      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    def destroy
      authorize! :destroy, @topic

      sub_topic_orders = @topic.sub_topic_orders
      @topic.remove_from_order(sub_topic_orders,@topic.id) if sub_topic_orders.present?

      render_errors('Could not delete topic') && return unless @topic.remove(params[:data], current_user)

      render json: {}, status: 204
    end

    def share_with_relationships
      topic = current_user.following_topics.find(params[:id])
      topic.share_with_all_relationships(params, current_user)

      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    def join
      topic = Topic.find_by(id: params[:id])
      render_errors('Could not find topic') && return if topic.blank?

      current_user.follow(topic)
      current_user.follow_tips_from_users(topic, topic.user_followers - [current_user])

      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    def leave
      topic = Topic.find_by(id: params[:id])
      render_errors('Could not find topic') && return if topic.blank?

      current_user.stop_following(topic)
      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    # TODO: Create a VotesController to handle likes, stars and votes
    # Move star and unstar methods below to that controller
    # Note: Will require a change on the front end.
    def star
      topic = Topic.find(params[:id])
      VoteService.add_vote(current_user, topic, :star)

      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    def unstar
      topic = Topic.find(params[:id])
      VoteService.remove_vote(current_user, topic, :star)

      render json: topic, status: :ok, location: [:v2, topic], serializer: TopicDetailSerializer
    end

    def explore
      params[:page] ||= { number: 1 }
      params[:page][:number] ||= 1

      topics = Topic.includes(:topic_preferences).without_root
      topics = topics.followed_by(ENV['EDITOR_EMAIL']) if current_domain.public_domain?
      topics = topics.filter_with_current_user(current_user, filter_or_default(params))
      topics = topics.sort(params[:sort])
      topics = paginate(topics)

      page_data = {
        current_page: params[:page][:number].to_i,
        total_count:  topics.total_count,
        total_pages:  topics.total_pages
      }

      render json: topics, each_serializer: TopicSmallSerializer, meta: build_meta_data(page_data), status: :ok
    end

    def suggested_topics
      topic_titles = GlobalTemplate.suggested_topics
      render json: topic_titles, status: :ok, meta: build_meta_data
    end

    private

    # rubocop:disable Metrics/MethodLength
    def topic_params
      params.require(:data).permit(
        :join_if_existed,
        :type,
        attributes: [:title, :description, :parent_id, :default_view_id, :image, :remote_image_url, :show_tips_on_parent_topic, :cards_hidden, :is_secret, :apply_to_all_childrens],
        relationships: [
          topic_preferences: [
            {
              data: [
                :background_color_index,
                :background_image,
                :share_following,
                :share_public
              ]
            }
          ],
          roles: [{
            data: [
              :name,
              :user_id,
              :_destroy
            ]
          }],
          topic_permission: [
            {
              data: [
                :id,
                access_hash: [
                  create_topic:     [roles: []],
                  edit_topic:       [roles: []],
                  destroy_topic:    [roles: []],
                  create_tip:       [roles: []],
                  edit_tip:         [roles: []],
                  destroy_tip:      [roles: []],
                  like_tip:         [roles: []],
                  comment_tip:      [roles: []],
                  create_question:  [roles: []],
                  edit_question:    [roles: []],
                  destroy_question: [roles: []],
                  like_question:    [roles: []],
                  answer_question:  [roles: []]
                ]
              ]
            }
          ]
        ]
      )
    end
    # rubocop:enable Metrics/MethodLength

    def reorder_params
      params.require(:data).permit(:topic_id, preceding_topics: [])
    end

    def load_topic_permission
      return unless topic_params_has_data_for(:topic_permission)

      @topic.topic_permission_attributes = topic_params[:relationships][:topic_permission][:data]
    end

    def load_roles
      return unless topic_params_has_data_for(:roles)

      topic_params[:relationships][:roles][:data].each do |role|
        user = User.find(role[:user_id])

        next unless user
        next unless role?(role[:name])

        if role[:_destroy]
          next if removing_owner?(@topic, role[:name], user)
          user.remove_role role[:name], @topic
        else
          user.add_role role[:name], @topic
        end
      end
    end

    def role?(name)
      Role::TYPES.include?(name)
    end

    def removing_owner?(topic, role, user)
      topic.user == user && role.to_sym == :admin
    end

    def create_default_topic_preferences(topic, topic_params)
      return unless topic_params_has_data_for(:topic_preferences)

      topic_preferences = topic.topic_preferences.new(topic_params[:relationships][:topic_preferences][:data][0])
      topic_preferences.user_id = current_user.id
      topic_preferences.save
    end

    def update_topic_preferences(topic, topic_params)
      return unless topic_params_has_data_for(:topic_preferences)

      topic_preference = topic.topic_preferences.find_by_user_id(current_user.id)

      return unless topic_preference

      topic_preference.update_attributes(topic_params[:relationships][:topic_preferences][:data][0])
    end

    def filter_or_default(params)
      params.key?(:filter) ? params[:filter] : { topics: 'not_following' }
    end

    def topic_params_has_data_for(key)
      params_hash = topic_params.with_indifferent_access
      params_hash.key?(:relationships) &&
        params_hash[:relationships].key?(key) &&
        params_hash[:relationships][key].key?(:data) &&
        params_hash[:relationships][key][:data].size > 0
    end

    def load_topic
      @topic = Topic.includes(:share_settings, :topic_permission, :user, :users_roles).find_by(id: params[:id])
    end

    def current_ability
      current_user.current_topic = @topic.try(:root)
      @current_ability ||= Ability.new(current_user, current_domain, @topic.try(:root))
    end

    def new_or_existing_topic(topic_params)
      if topic_params[:attributes][:parent_id]
        parent_id = topic_params[:attributes][:parent_id]
        matching_title = Topic.where(title: topic_params[:attributes][:title])
        topic = matching_title.find_by("substring(ancestry, '[^/]*$') = ?", parent_id.to_s)
      else
        topic = Topic.without_root.find_by_title(topic_params[:attributes][:title])
      end

      current_user.follow(topic) unless topic.blank?
      topic = current_user.topics.new(topic_params[:attributes]) if topic.blank?

      topic
    end

    def build_topics(params)
      filter = build_filter(params)
      topics = Topic.roots
      topics = Topic.children_of(params[:parent_id].to_i) if params[:parent_id].present?
      topics = topics.filter(filter).uniq
      
      secret_topics = topics.where(is_secret: true).followed_by(current_user)
      topics = topics.where(is_secret: false)
      topics = topics + secret_topics
      
      topics = Topic.where(id: topics.map(&:id))
      
      if params.key?(:sort)
        topics = topics.sort(params[:sort])
      else
        topics = build_topics_with_custom_order(topics, params[:parent_id].to_i)
      end

      topics = exclude_subtopics_private(topics) if params[:parent_id].present? and current_domain.tenant_name == 'public'
      topics = topics.order_by_ids(params[:filter][:topicIDs]) if params[:filter].try(:[], 'topicIDs').present?

      topics = paginate(topics)
      
      topics
    end

    def exclude_subtopics_private(topics)
      users_following = current_user.following_users.pluck(:id)
      users_following << current_user.id #To allow subtopics created by current_user
      topics = topics.to_a.delete_if { |topic| users_following.include?(topic.user_id) == false and
                                               is_subtopic_cards_shared?(topic) == false}
      topics
    end

    def is_subtopic_cards_shared?(topic)
      subtopic_tips = topic.tip_followers

      subtopic_tips.each do |tip|
        return true if tip.user_followers.find_by_id(current_user).present?
      end
      return false
    end  

    def build_topics_with_custom_order(topic_scope, parent_id = nil)
      context_id = Context.generate_id(
        user: current_user.id,
        domain: current_domain.id,
        topic: parent_id
      )

      context_join = 'LEFT JOIN context_topics ON context_topics.topic_id = topics.id'
      context_join += " AND context_topics.context_id = '#{context_id}'"

      topics = topic_scope.joins(context_join)
               .select('topics.*, context_topics.position')
               .order('context_topics.position')
               .order(title: 'ASC')

      topics
    end

    def build_filter(params)
      # REFACTOR: Not sure how, but this method seems to smell
      # will default to followed_by_user, unless something below changes

      params = build_default_scope(params) unless scope_all?(params)

      # unless current_user.guest_of?(current_domain)
      #   # REMOVE FOLLOWED_BY_USER IF ANOTHER SCOPE IS BEING PASSED IN
      #   params[:filter].delete(:followed_by_user) if scope_all?(params)
      #   params[:filter].delete(:followed_by_user) if params[:filter].key?(:shared_with)
      # end

      # ensure guests only get to see hives they follow
      # but allow them all if within_group
      if current_user.guest_of?(current_domain)
        if params.key?(:filter) && !params[:filter].key?(:within_group)
          params[:filter][:followed_by_user] = current_user.id
        end

        # Ensure guest is only able to view topics shared with them
        params[:filter] ||= {}
        params[:filter][:shared_with] = current_user.id
      end

      params[:filter] = {} unless params.key?(:filter)
      params[:filter].merge(current_user_id: current_user.id)
    end

    def build_default_scope(params)
      return params if params.key?(:filter)
      params[:filter] = { followed_by_user: current_user.id }
      params
    end

    def scope_all?(params)
      return true if params[:search_all_hives].present?
      return true if params[:parent_id].present?
      return true if current_domain.public_access?
      return false unless params.key?(:filter)

      params[:filter].key?(:not_followed_by_user)
    end

    def check_topic_preference
      return false unless current_user.nil?
      return false unless @topic
      load_topic
      @topic_preferences = @topic.topic_preferences.find_by(user_id: params[:user_id])
      case @topic_preferences.link_option
      when "link"
        true
      when "linkWithPassword"
        flag = false
        msg = "Password required"
        if params[:link_password].present?
          flag = @topic_preferences.link_password == params[:link_password]
          msg = "Password Does not match"
        end
        (flag) ? true : (render json: { msg: msg })
      when "linkWithAccess"
        msg = "Access required"
        (flag) ? true : (render json: {msg: msg })
      else
        false
      end
    end

    def find_user
      return current_user unless current_user.nil?
      current_user = User.find(params[:user_id])
    end
  end
end
# rubocop:enable Metrics/ClassLength
