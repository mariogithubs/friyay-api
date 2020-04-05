FactoryGirl.define do
  factory :slack_member do
  	association :user, factory: :user, strategy: :create
  	association :slack_team, factory: :slack_team, strategy: :create
    name 'mukesh'
    slack_member_id 'UCR6NDCKS'
  end
end
