require 'rails_helper'

describe ShareSetting do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  it 'has a valid factory' do
    expect(build(:tip)).to be_valid
  end

  describe 'ActiveModel validations' do
    it { should validate_presence_of(:user_id) }
  end
end
