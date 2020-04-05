FactoryGirl.define do
  factory :user do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    # username { FFaker::Internet.user_name }
    password '12345678'
    password_confirmation '12345678'
  end

  factory :member, class: User do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    username { FFaker::Internet.user_name }
    password '12345678'
    password_confirmation '12345678'
  end

  factory :member2, class: User do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    username { FFaker::Internet.user_name }
    password '12345678'
    password_confirmation '12345678'
  end

  factory :power, class: User do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    username { FFaker::Internet.user_name }
    password '12345678'
    password_confirmation '12345678'
  end

  factory :admin, class: User do
    email { 'anthony@tiphive.com' }
    first_name { 'Anthony' }
    last_name { 'Lassiter' }
    username { 'alassiter' }
    password '12345678'
    password_confirmation '12345678'
  end
end
