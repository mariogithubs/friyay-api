FactoryGirl.define do
  factory :comment do
    body { FFaker::Lorem.paragraphs(1) }

    # FUTURE
    # with_location:
    # longitude, latitude, location
  end
end
