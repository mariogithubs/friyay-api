FactoryGirl.define do
  factory :domain_membership do
    association :user, factory: :user, strategy: :create
    association :domain, factory: :domain, strategy: :create
  end
end
