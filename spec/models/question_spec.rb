require 'rails_helper'

describe Question do
  describe 'attributes' do
    it { should have_attribute(:title) }
    it { should have_attribute(:body) }
    it { should have_attribute(:share_public) }
  end

  describe 'associations' do
    it { should have_many(:followings) }
    it { should belong_to(:user) }
  end

  it 'has a valid factory' do
    expect(build(:question, user: build(:user))).to be_valid
  end

  describe 'ActiveModel validations' do
    it { should validate_presence_of(:user) }
  end

  describe '.viewable_by' do
    # TEST COVERED IN CONTROLLER FOR NOW
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:question_list) { create_list(:question, 3, user: user) }
  end
end
