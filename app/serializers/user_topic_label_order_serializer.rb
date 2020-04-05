class UserTopicLabelOrderSerializer
  include FastJsonapi::ObjectSerializer

  attributes :user_id, :topic_id, :label_order_id

end