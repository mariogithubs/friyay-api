FactoryGirl.define do
  factory :slack_team do
    association :domain, factory: :domain, strategy: :create
    team_name 'testing'
    team_id 'TCR6NDBUY'
    access_token 'xoxp-433226453984-433226454672-433852934531-99592b4a9523f56044c342a8e200e3a4'
  end
end
