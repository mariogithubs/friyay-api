FactoryGirl.define do
  factory :context do
    sequence :context_uniq_id do |n|
      "user:1:domain:1:topic:#{n}"
    end
    default true
    sequence :topic_id
  end
end
