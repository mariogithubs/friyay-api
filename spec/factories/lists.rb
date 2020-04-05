FactoryGirl.define do
  factory :list do
    association :user, factory: :user, strategy: :create
    name 'My List'
  end
end
