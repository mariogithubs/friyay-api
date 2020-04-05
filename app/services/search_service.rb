# TOOD: This is a misnomer. We are only using this for grabbing sharing items
# Perhaps we need to rename this so that its not a "search service"
class SearchService
  include TipHive

  attr_accessor :query, :params, :current_domain, :current_user, :resources, :page_number, :page_size

  def initialize(current_domain, current_user, params = {})
    @current_domain = current_domain
    @current_user = current_user
    @query = params[:q]
    @resources = params[:resources] || 'User,Group'
    @page_number = params[:page][:number]
    @page_size = params[:page][:size]
    @params = params
  end

  def sharing_items
    @sharing_items = current_domain.public_domain? ? follow_results : sunspot_search

    return [] if @sharing_items.blank?

    @sharing_items.sort_by(&:name)
  end

  private

  def sunspot_search
    search = Sunspot.search(resources.split(',').collect(&:constantize)) do
      fulltext(query)

      with(:tenant_name, Apartment::Tenant.current) unless current_domain.public_domain?

      order_by(:kind, :asc)
      order_by(:name, :asc)

      paginate(page: page_number, per_page: page_size)
    end

    results = search.results.collect { |result| SharingResource.new(result) }.reject { |res| res.name.blank? }
    viewable_results = TipHiveSearch.viewable_results(results, current_user)

    sharing_items = remove_groups_not_followed(viewable_results).try(:uniq)
    sharing_items = remove_users_not_followed(sharing_items).try(:uniq) { |item| [item.id, item.label] }
    sharing_items = remove_users_not_active(sharing_items) unless current_domain.public_domain? 

    sharing_items
  end

  def follow_results
    return sunspot_search unless query == '*'
    following_resources = current_user.following_users + current_user.following_groups + [current_user]

    sharing_items = following_resources.map do |resource|
      SharingResource.new(resource)
    end

    sharing_items
  end

  def remove_groups_not_followed(results)
    return if results.blank?

    group_followed_ids = current_user.group_memberships.pluck(:id)

    results.reject { |result| result.resource_type == 'groups' && !group_followed_ids.include?(result.id) }
  end

  def remove_users_not_followed(results)
    # Don't remove users if user is a member
    return results if (current_user.member_of?(current_domain) || current_user.power_of?(current_domain)) && !current_domain.public_domain?
    return results if results.blank?

    user_followed_ids = current_user.following_users.pluck(:id)
    user_followed_ids << current_user.id

    results.reject { |result| result.label == 'Member' && !user_followed_ids.include?(result.id) }
  end

  def remove_users_not_active(results)
    return if results.blank?

    domain_users = current_domain.domain_members.active.try(:pluck,:id)
    results.reject { |result| result.resource_type == 'users' && !domain_users.include?(result.id) }
  end
end
