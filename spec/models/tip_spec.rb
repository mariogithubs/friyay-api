require 'rails_helper'

describe Tip do
  describe 'attributes' do
    it { should respond_to(:id) }
    it { should respond_to(:user_id) }
    it { should respond_to(:title) }
    it { should respond_to(:body) }
    it { should respond_to(:color_index) }
    it { should respond_to(:access_key) }
    it { should respond_to(:share_public) }
    it { should respond_to(:share_following) }
    it { should respond_to(:properties) }
    it { should respond_to(:statistics) }
    it { should respond_to(:created_at) }
    it { should respond_to(:updated_at) }
    it { should respond_to(:expiration_date) }
    it { should respond_to(:is_disabled) }
    it { should respond_to(:cached_scoped_like_votes_total) }
    it { should respond_to(:cached_scoped_like_votes_score) }
    it { should respond_to(:cached_scoped_like_votes_up) }
    it { should respond_to(:cached_scoped_like_votes_down) }
    it { should respond_to(:cached_scoped_like_weighted_score) }
    it { should respond_to(:cached_scoped_like_weighted_total) }
    it { should respond_to(:cached_scoped_like_weighted_average) }
    # it { should respond_to(:body_md) }
    it { should respond_to(:attachments_json) }
    it { should respond_to(:start_date) }
    it { should respond_to(:due_date) }
    it { should respond_to(:completion_date) }
    it { should respond_to(:completed_percentage) }
    it { should respond_to(:work_estimation) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:followings) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:comment_threads) }

    xit { is_expected.to belong_to(:question) }
    xit { is_expected.to have_many(:pictures) }

    it 'has a valid factory' do
      expect(build(:tip)).to be_valid
    end

    describe 'ActiveModel validations' do
      it { should validate_presence_of(:user) }
    end

    context 'when tip created' do
      let(:tip) { create(:tip) }
      it { expect(tip.color_index).to be_between(1, 7).inclusive }
      # it { expect(tip.topics.size).to be >= 1 }
      # it { expect(tip.topics.first).to be_a(Topic) }
    end
  end

  describe 'scopes' do
    let(:tip_list) { create_list(:tip, 6) }

    describe 'filter' do
      before do
        tip_list[0..2].each do |tip|
          tip.update_attribute(:created_at, tip.created_at - 3.months)
        end
      end

      it { expect(described_class.filter(type: 'latest').count).to eql(3) }
      it { expect(described_class.filter(type: 'latest').first.created_at).to be > Time.now.utc - 30.days }
    end
  end

  # TODO: IS THERE ANY WAY TO REDO THIS TO AVOID USERS FOLLOWING TIPS
  # describe '.viewable_by' do
  #   let(:creator) { create(:user) }
  #   let(:user) { create(:user) }
  #   let(:topic) { create(:topic, user: creator) }
  #   let(:tip_list) { create_list(:tip, 2, user: creator) }
  #   let(:viewable_tips) { create_list(:tip, 3, user: creator, share_public: true) }

  #   before do
  #     user.follow(topic)
  #     user.follow(creator)
  #     viewable_tips.each { |tip| tip.follow(topic) }
  #   end

  #   it { expect(described_class.viewable_by(user).count).to eql(3) }
  # end
end

describe Tip, :versioning => true do
  let(:tip) { create(:tip) }
  it 'is possible to do assertions on version attributes' do
    #expect(tip.versions.length).to eql(1) Versioning is disabled on create
    tip.update!(title: 'Tom')
    expect(tip.versions.length).to eql(1)
    tip.update!(title: 'Tom1')
    expect(tip.versions.length).to eql(2)
  end
end
