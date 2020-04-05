class UserTopicPeopleOrderSerializer
  include FastJsonapi::ObjectSerializer

  attributes :user_id, :topic_id, :people_order_id

end
