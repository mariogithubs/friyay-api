require 'rails_helper'

describe TopicPreference do
  let(:topic) { create(:topic) }

  it { expect(build(:topic_preference)).to be_valid }

  describe 'ActiveModel validations' do
    it { should validate_presence_of(:topic_id) }
    it { should validate_presence_of(:user_id) }
  end

  let(:topic_preference) { build(:topic_preference) }

  it 'generates a background color on create' do
    expect(topic_preference.background_color_index).to be_between(1, 7).inclusive
  end

  describe '#viewable_tips_for(user)' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:mary) { create(:user, first_name: 'Mary') }
    let(:viewable_tips) { create_list(:tip, 3, user: mary, share_public: true) }
    let(:non_viewable_tip) { create(:tip, user: mary) }

    before do
      bob.follow(topic)
      mary.follow(topic)
      viewable_tips.each { |tip| tip.follow(topic) }
      non_viewable_tip.follow(topic)
    end

    it { expect(viewable_tips).to_not be_nil }
  end
end
