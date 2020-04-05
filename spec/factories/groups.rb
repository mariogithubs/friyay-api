FactoryGirl.define do
  factory :group do
    association :user, factory: :user, strategy: :create
    title { FFaker::Lorem.words(rand(1..4)).join(' ').titleize }
    join_type :anyone
    # avatar do
    #   Rack::Test::UploadedFile.new(
    #     File.join(
    #       Rails.root, 'spec', 'support', 'images', 'avatar-image.jpg'
    #     )
    #   )
    # end
    # background_image do
    #   Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'images', 'background-image.jpg'))
    # end
  end

  factory :group_with_http_upload, class: Group do
    association :user, factory: :user, strategy: :create
    title { FFaker::Lorem.words(rand(1..4)).join(' ').titleize }
    join_type :anyone
    # avatar do
    #   ActionDispatch::Http::UploadedFile.new(
    #     filename: 'test-image-1.jpg',
    #     content_type: 'image/jpeg',
    #     tempfile: File.new(Rails.root.join('spec', 'support', 'images', 'avatar-image.jpg'))
    #   )
    # end
  end
end
