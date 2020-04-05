FactoryGirl.define do
  factory :topic_preference do
    association :topic, factory: :topic, strategy: :create
    association :user, factory: :user, strategy: :create
    background_color_index 4
    share_following true
    share_public false
    # background_image do
    #   Rack::Test::UploadedFile.new(
    #     File.join(Rails.root, 'spec', 'support', 'images', 'avatar-image.jpg')
    #   )
    # end
  end
end
