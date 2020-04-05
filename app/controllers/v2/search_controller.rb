module V2
  class SearchController < ApplicationController
    include TipHive

    before_action :authenticate_user!

    def index
      render_errors('A search term was not entered') && return if params[:q].nil?
      render_errors('You may not perform this search') && return unless scope_allowed(params)

      results = TipHiveSearch.search(params[:q], build_options(params))

      results = results.map { |result| SearchResource.new(result) }

      results = TipHiveSearch.viewable_results(results, current_user)
      results = remove_archived_tips(results)
      results = remove_secret_topic(results)
      results = personal_hive_results(results) if current_domain.tenant_name == 'public'
      render_empty_set && return if results.blank?

      # TODO: use TipHiveSearchSerializer with custom values for just what we need
      render json: results, status: :ok
    end

    private

    def remove_archived_tips(results)
      results.delete_if { |result| result.resource_type == 'tips' && result.is_disabled == true }
    end

    def remove_secret_topic(results)
      topics_followed = current_user.following_topics.pluck(:id)
      results.delete_if { |result|  result.resource_type == 'topics' && (Topic.find(result.id).is_secret == true && topics_followed.include?(result.id) == false) }
    end

    def personal_hive_results(results)
      users_followed = current_user.following_users.pluck(:id)
      tips_followed = current_user.following_tips.pluck(:id)
      topics_followed = current_user.following_topics.pluck(:id)

      results.delete_if { |result| (result.resource_type == 'users' && 
                                   users_followed.include?(result.id) == false) or
                                   (result.resource_type == 'tips' && 
                                   tips_followed.include?(result.id) == false) or
                                   (result.resource_type == 'topics' && 
                                   topics_followed.include?(result.id) == false)}

      results
    end

    def build_options(params)
      {
        resources: build_search_classes(params),
        within: params[:within],
        within_id: params[:within_id],
        page_number: params['page'].try(:[], 'number'),
        page_size: params['page'].try(:[], 'size')
      }
    end

    def build_search_classes(params)
      available_classes = %w(User Topic Tip Group)
      # available_classes = %w(DomainMember Topic Tip Group) if current_domain.private_domain?

      Rails.logger.info "====> Building search classes #{available_classes} with params #{params} " \
                        "for domain '#{Apartment::Tenant.current}'"

      klasses = params[:resources].split(',').map(&:capitalize) if params[:resources]
      return klasses.map(&:constantize) if klasses.present? && (klasses - available_classes).empty?

      available_classes.map(&:constantize)
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def scope_allowed(params)
      true
      # TODO: A future feature!!
      # return false unless params[:resources] == "Topic"
      # return false unless (params[:within].present? && params[:within_id].present?)
      # return false unless (['tip','question'] - resources_array(params[:resources])).empty?

      # # return true unless params[:within].present? && params[:within_id].present?
      # # return true if ['tip','question'].include?(params[:resources].try(:downcase))

      # true
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
