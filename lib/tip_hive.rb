module TipHive
  # rubocop:disable Metrics/MethodLength
  def self.reserved_domain?(domain_name)
    domain_list = %w(
      about
      api
      assets
      beta
      cdn
      ci
      db
      dev
      development
      enterprise
      errors
      newprod
      prod
      production
      staging
      team
      tiphive
      www
      frontend
      stagingapi
      email
      admin
      links
      home
      my
      anthony
      madiken
      shannice
      joost
      long
      payal
    )

    # TODO: make an api_regex to prevent all api + number domains. api1 - api(infinity)
    api_regex = /^api(\d+)?$/

    models = ActiveRecord::Base.descendants
    model_name_list = models.select { |x| x.try(:name).try(:match, /::/).nil? }
    model_name_list = model_name_list.map(&:name).compact.map(&:downcase)
    model_name_list += model_name_list.map(&:pluralize)

    return true if domain_name.downcase.match(api_regex)
    return true if model_name_list.include?(domain_name.downcase)
    domain_list.include?(domain_name.downcase)
  end
  # rubocop:enable Metrics/MethodLength

  class TipHiveSearch
    def self.search(query, options)
      resources = options[:resources]
      # within_resource = options[:within]
      # within_resource_id = options[:within_id]
      page_number = options[:page_number] || 1
      page_size = options[:page_size] || 30

      # TODO: Implement these if we are going to user them, else remove them
      field_list = options[:field_list]
      field = options[:field]

      return [] if query.blank? || resources.blank?

      search = Sunspot.search(resources) do
        fulltext(query) do
          phrase_fields title: 4.0
          boost_fields title: 2.0

          if field_list.present?
            search_fields = field_list.split(',')
            search_fields.each do |search_field|
              fields(search_field)
            end
          end
          fields field if field.present?
        end

        with :tenant_name, Apartment::Tenant.current

        paginate(page: page_number.to_i, per_page: page_size.to_i)
      end

      search.results
    end

    def current_page(page_number)
      page_number.to_i > 0 ? page_number.to_i : 1
    end

    def per_page(page_size)
      page_size.to_i > 0 ? page_size.to_i : 10
    end

    def self.viewable_results(resultCollection, current_user)
      tips = resultCollection.select { |result| result.resource_type == 'tips' }
      return resultCollection if tips.blank?

      viewable_tip_ids = current_user.viewable_tips.pluck(:id)

      viewable_ids = tips.map(&:id) & viewable_tip_ids

      resultCollection.delete_if { |result| result.resource_type == 'tips' && !viewable_ids.include?(result.id) }
    end

    # TODO: this needs to find tips following topic, then search withing those tips
    # def perform_search_within(within_resource, query)
    #   return [] if within_resource_id.blank?
    #   return [] unless within_resource == 'topic' # This only works for Topics currently

    #   search = Sunspot.search(resources) do
    #     # Hard coded for Tip
    #     # TODO: allow us to search for a resource of our choice within a topic
    #     fulltext(query)
    #     with(:topic_id).any_of([within_resource_id])
    #   end

    #   search.results
    # end
  end
end
