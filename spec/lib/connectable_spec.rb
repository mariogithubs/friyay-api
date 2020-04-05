require 'rails_helper'

describe Connectable do
  include ControllerHelpers::JsonHelpers

  context 'when triggering after_create' do
    describe '#share_with_creator' do
      let(:creator) { create(:user) }
      let(:tip) { create(:tip, user: creator) }

      it { expect(tip.user_followers).to include(creator) }
    end

    describe '#share_with_creator' do
      let(:creator) { create(:user) }
      let(:topic) { create(:topic, :with_subtopics, user: creator) }
      let(:subtopic) { topic.children.first }

      it { expect(topic.user_followers).to include(creator) }
      it { expect(subtopic.user_followers).to include(creator) }
    end
  end

  describe '#follow_multiple_resources' do
    context 'when following two topics' do
      let(:topics) { create_list(:topic, 2) }
      let(:tip) { create(:tip) }

      before do
        tip.follow_multiple_resources(:topics, tiphive_serialize(topics).as_json)
      end

      it { expect(tip.topics.count).to eql(topics.count) }
    end

    context 'when following root if object has root' do
      let(:topic) { create(:topic) }
      let(:subtopic) { create(:topic, parent: topic) }
      let(:tip) { create(:tip) }

      before do
        tip.follow_multiple_resources(:topics, tiphive_serialize(subtopic).as_json)
      end

      it { expect(tip.subtopics({}).map(&:id)).to include(subtopic.id) }
      it { expect(tip.topics.map(&:id)).to include(topic.id) }
    end
  end

  describe '#share_with_relationships(users)' do
    # TODO: change this test to lookk for notifcation, not connection
    context 'when sharing a resource' do
      let(:users) { create_list(:user, 3) }
      let(:tip) { create(:tip, user: users.first) }

      before do
        users.each { |user| user.join(current_domain) }
        tip.share_with_relationships('users', UserSerializer.new(users, { params: { domain: current_domain } }).serializable_hash)
      end

      it { expect(tip.user_followers.count).to eql(3) }
    end

    context 'when sharing a topic' do
      let(:users) { create_list(:user, 3) }
      let(:topic) { create(:topic, :with_subtopics, user: users.first) }
      let(:subtopic) { topic.children.first }
      let(:subtopic_child) { create(:topic, parent: subtopic, user: users.first) }

      before do
        subtopic_child
        users.each { |user| user.join(current_domain) }
        subtopic.share_with_relationships('users', UserSerializer.new(users, { params: { domain: current_domain } }).serializable_hash)
      end

      it 'follows self and children' do
        # The creator, and two followers
        expect(subtopic.user_followers.count).to eql 3
        expect(subtopic_child.user_followers.count).to eql 3
      end

      it 'follows the root of a subtopic' do
        expect(topic.user_followers.count).to eql(3)
      end
    end
  end

  describe '#share_with_relationships(groups)' do
    let(:group) { create(:group) }
    let(:topic) { create(:topic, user: create(:user)) }

    context 'when passing array of groups' do
      before do
        topic.share_with_relationships('groups', tiphive_serialize([group]).as_json)
      end

      it { expect(topic.group_followers.count).to eq 1 }
    end

    context 'when not passing any groups' do
      before do
        topic.share_with_relationships('groups', data: {})
      end

      it { expect(topic.group_followers.count).to eq 0 }
    end
  end

  describe 'follow_tips' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:member) { create(:user) }
    let(:guest) { create(:user) }
    let(:topic) { create(:topic, user: bob) }
    let(:tip) { create(:tip, user: bob) }

    before do
      tip.follow(topic)
      member.join(current_domain, as: 'member')
      guest.join(current_domain, as: 'guest')

      topic.follow_tips(member)
      topic.follow_tips(guest)
    end

    it { expect(member.following_tips).to include(tip) }
    it { expect(guest.following_tips).to_not include(tip) }
  end
end
