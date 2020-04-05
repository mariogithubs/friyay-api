FactoryGirl.define do
  factory :label do
    association :user, factory: :user, strategy: :create
    name FFaker::Lorem.word
    color '#0000ff'
    kind 'private'
  end
end
