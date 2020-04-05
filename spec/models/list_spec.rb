require 'rails_helper'

RSpec.describe List, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:followings) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'valid factory' do
    it { expect(build(:list)).to be_valid }
  end

  describe 'connections' do
    let(:topic) { create(:topic) }
    let(:user) { create(:user) }
    let(:list) { create(:list) }

    before do
      topic
      user.follow(list)
    end

    it { expect { list.follow(topic) }.to change { Follow.count }.by(1) }
    it { expect(list.followers_count).to eql(1) }
  end
end
