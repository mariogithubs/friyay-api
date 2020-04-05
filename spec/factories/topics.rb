FactoryGirl.define do
  factory :topic do
    title { [FFaker::Lorem.words(rand(1..8)), rand(10_000).to_s].join(' ').titleize }
    association :user, factory: :user, strategy: :create

    trait :with_subtopics do
      transient do
        number_of_subtopics 3
      end

      after(:create) do |topic, evaluator|
        options = { parent: topic, user: topic.user }
        create_list(:topic, evaluator.number_of_subtopics, options)
      end
    end
  end
end
