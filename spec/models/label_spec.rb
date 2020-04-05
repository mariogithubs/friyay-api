require 'rails_helper'

RSpec.describe Label, type: :model do
  it 'has a valid factory' do
    expect(build(:tip)).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end
end
