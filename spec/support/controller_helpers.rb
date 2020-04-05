module ControllerHelpers
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body, symbolize_names: true)
    end

    def tiphive_serialize(objects)
      objects = [objects] unless objects.is_a?(Array)

      if objects.first.class.name == 'Image'
        serializer = AttachmentSerializer
      else
        serializer = (objects.first.class.name + 'Serializer').constantize
      end

      # serializer = ActiveModel::Serializer::CollectionSerializer.new(

      serializer = ActiveModel::Serializer::ArraySerializer.new(
        objects,
        each_serializer: serializer,
        scope: defined?(user) ? user : User.new
      )

      # ActiveModelSerializers::Adapter.create(serializer)

      ActiveModel::Serializer::Adapter.create(serializer)
    end

    def current_domain
      @current_domain ||= Domain.find_by(tenant_name: Apartment::Tenant.current)
    end
  end

  module ContextHelpers
    def build_context_join(resource_hash)
      context_id = Context.generate_id(
        user: resource_hash[:user].try(:id),
        domain: resource_hash[:domain].try(:id),
        group: resource_hash[:group].try(:id),
        topic: resource_hash[:topic].try(:id)
      )

      context_join = 'LEFT JOIN context_tips ON context_tips.tip_id = tips.id'
      context_join += " AND context_tips.context_id = '#{context_id}'"

      context_join
    end
  end
end
