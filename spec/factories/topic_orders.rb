FactoryGirl.define do
  factory :topic_order do
    association :topic, factory: :topic, strategy: :create
    
  end
end
