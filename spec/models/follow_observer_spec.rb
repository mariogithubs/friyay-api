require 'rails_helper'

describe FollowObserver do
  describe '#after_create' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:mary) { create(:user, first_name: 'Mary') }
    let(:creator) { create(:user, first_name: 'Sally') }
    let(:topic) { create(:topic, user: creator) }

    context 'when user following topic' do
      before do
        topic
        mary.follow(topic)
        bob.follow(topic)
      end

      it { expect(topic.topic_preferences.for_user(creator).follow_all_users?).to be true }
      it { expect(topic.topic_preferences.for_user(mary).follow_all_users?).to be true }
    end
  end
end
