FactoryGirl.define do
  factory :tip do
    association :user, factory: :user, strategy: :create
    title { FFaker::Lorem.words(rand(1..4)).join(' ').titleize }
    body { FFaker::Lorem.paragraphs(rand(1..3)).map { |p| "<p>#{p}</p>" }.join }
    value 5
    effort 5
  end
end
