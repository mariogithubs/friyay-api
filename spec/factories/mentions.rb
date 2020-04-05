FactoryGirl.define do
  factory :mention do
    mentionable_id 1
    mentionable_type 'MyString'
    text 'MyText'
  end
end
