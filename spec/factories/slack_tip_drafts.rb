FactoryGirl.define do
  factory :slack_tip_draft do
    title "MyString"
    body "MyText"
    is_draft false
    slack_member nil
  end
end
