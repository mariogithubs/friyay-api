# include ActionDispatch::TestProces

FactoryGirl.define do
  factory :attachment do
    type 'Image'
    # file Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, '/spec/support/hamburger.png')))
    # file File.open(File.join(Rails.root, '/spec/support/hamburger.png'))
  end
end
