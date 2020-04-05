FactoryGirl.define do
  factory :slack_channel do
  	association :slack_team, factory: :slack_team, strategy: :create
    name "general"
    slack_channel_id "CCSV9G9QX"
  end
end
