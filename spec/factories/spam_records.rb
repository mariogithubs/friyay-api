FactoryGirl.define do
  factory :spam_record do
    to 'MyString'
    from 'MyString'
    subject 'MyString'
    html 'MyText'
    spam_score 'MyString'
    spam_report 'MyText'
    envelope 'MyString'
  end
end
