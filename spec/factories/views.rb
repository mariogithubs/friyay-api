FactoryGirl.define do
  factory :view do
    user_id 1
    name 'Default View'
    kind 'system'
    show_nested_tips true
  end
end
