require 'rails_helper'

describe Group do
  describe 'attributes' do
    # Is it necessary to test attributes?
    # Won't we know if other tests fail? Validations should be enough
  end

  describe 'associations' do
    it { should have_many(:followings) }
    it { should belong_to(:user) }
  end

  it 'has a valid factory' do
    expect(build(:group, user: build(:user))).to be_valid
  end

  describe 'ActiveModel validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:title) }
  end

  describe 'automated processes' do
    let(:group) { create(:group) }
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:mary) { create(:user, first_name: 'Mary') }

    it 'generates a color on create' do
      expect(group.color_index).to eql 8
    end

    it 'shares with all relationships' do
      expect(group.share_with_user_resources([bob, mary]))
    end
  end

  describe '#add_member_or_invite' do
    # Test each join_type
  end
end
