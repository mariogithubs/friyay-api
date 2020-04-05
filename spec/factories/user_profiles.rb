FactoryGirl.define do
  factory :user_profile do
    association :user, factory: :user
  end
end
