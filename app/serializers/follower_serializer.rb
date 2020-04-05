class FollowerSerializer
  include FastJsonapi::ObjectSerializer

  attribute :type do |object|
    object.class.model_name.plural
  end

end
