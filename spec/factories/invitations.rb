FactoryGirl.define do
  factory :invitation do
    association :user, factory: :user, strategy: :create
    email { FFaker::Internet.email }
    invitation_type :account
    association :invitable, factory: :user, strategy: :create
  end

  factory :domain_invitation, class: Invitation do
    association :user, factory: :user, strategy: :create
    email { FFaker::Internet.email }
    invitation_type :domain
    association :invitable, factory: :domain, strategy: :create
  end

  factory :guest_invitation, class: Invitation do
    association :user, factory: :user, strategy: :create
    email { FFaker::Internet.email }
    invitation_type :guest
    association :invitable, factory: :domain, strategy: :create
  end
end
