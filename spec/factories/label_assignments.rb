FactoryGirl.define do
  factory :label_assignment do
    association :label, strategy: :create
    item_id 1
    item_type 'Tip'
  end
end
