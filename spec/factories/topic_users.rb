FactoryGirl.define do
  factory :topic_user do
    follower_id
    user_id
    topic_id
    status
  end
end
