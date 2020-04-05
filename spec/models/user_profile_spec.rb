require 'rails_helper'

describe UserProfile do
  describe 'associations' do
    it { should belong_to :user }
  end

  it 'has a valid factory' do
    expect(build(:user_profile)).to be_valid
  end
  # let(:user) { build(:user) }

  # subject { user_profile }

  # it { should respond_to(:settings) }
end
