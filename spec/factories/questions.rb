FactoryGirl.define do
  factory :question do
    title { FFaker::Lorem.words(rand(1..4)).join(' ').titleize }
    body 'MyText'
  end
end
