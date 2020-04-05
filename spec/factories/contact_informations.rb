FactoryGirl.define do
  factory :contact_information do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    company_name { "xyz co ltd" }
    country { "usa" }
    state { "ny" }
    city {"Newyork"}
  end
end
