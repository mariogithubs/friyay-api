FactoryGirl.define do
  factory :domain do
    name { FFaker::Internet.domain_word }
    association :user, factory: :user
  end
end
