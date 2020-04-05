FactoryGirl.define do
  factory :global_template do
    template_type 'Topic'
    title { FFaker::Lorem.words(rand(1..4)).join(' ').titleize }
  end
end
