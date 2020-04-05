FactoryGirl.define do
  factory :share_setting do
    association :user, factory: :user, strategy: :create
  end
end
