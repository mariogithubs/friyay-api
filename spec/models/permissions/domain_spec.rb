require 'rails_helper'
require 'cancan/matchers'

describe Domain do
  describe '#abilities' do
    let(:default_permission) do
      {
        :create_topic => {:roles => ["member", "power"]},
        :edit_topic => {},
        :destroy_topic => {},
        :create_tip => {:roles => ["member", "power"]},
        :edit_tip => {:roles => ["member", "power"]},
        :destroy_tip => {:roles => ["member", "power"]},
        :like_tip => {:roles => ["member", "power"]},
        :comment_tip => {:roles => ["member", "power"]},
        :create_group => {:roles => ["member", "power"]},
        :edit_group => {:roles => ["member", "power"]},
        :destroy_group => {:roles => ["member", "power"]}
      }
    end

    # START HERE: test group permissions

    describe 'default permissions upon create' do
      context 'default permissions should apply automatically for a public domain' do
        let(:domain) { build(:domain) }

        it { expect(domain.domain_permission).to eq nil }
        it { expect(domain.permission).to eq default_permission }
      end

      context 'default permissions should apply automatically for a new private domain' do
        let(:domain) { create(:domain) }

        it { expect(domain.domain_permission).to eq nil }
        it { expect(domain.permission).to eq default_permission }
      end
    end

    describe 'test default abilities for domain' do
      let(:admin) { create(:user) }
      let(:member) { create(:user) }

      before do
        member.join(domain)
      end

      context 'Private Domain MEMBER abilities' do
        let(:domain) { create(:domain, user: admin) }

        subject(:ability) { Ability.new(member, domain) }

        let(:tip)       { create(:tip, user: admin) }
        let(:topic)     { create(:topic, user: admin) }

        it { should be_able_to(:create, Topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }
        it { should be_able_to(:update, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should_not be_able_to(:update, topic) }
        it { should_not be_able_to(:destroy, topic) }

        it { should_not be_able_to(:update, domain) }
      end

      context 'Private Domain ADMIN abilities' do
        let(:domain) { create(:domain, user: admin) }

        subject(:ability) { Ability.new(admin, domain) }

        let(:tip)       { create(:tip, user: member) }
        let(:topic)     { create(:topic, user: member) }

        it { should be_able_to(:create, Topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should be_able_to(:update, topic) }
        it { should be_able_to(:destroy, topic) }

        it { should be_able_to(:update, domain) }
      end

      context 'Public Domain member abilities' do
        let(:domain) { build(:domain, user: admin) }

        subject(:ability) { Ability.new(member, domain) }

        let(:tip)       { create(:tip, user: admin) }
        let(:topic)     { create(:topic, user: admin) }

        it { should be_able_to(:create, Topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }
        it { should be_able_to(:update, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should_not be_able_to(:update, topic) }
        it { should_not be_able_to(:destroy, topic) }

        it { should_not be_able_to(:update, domain) }
      end
    end

    describe 'test custom abilities for private domain' do
      let(:admin) { create(:user) }
      let(:member) { create(:user) }

      let(:domain) { create(:domain, user: admin) }

      before do
        member.join(domain)

        domain.update_attributes(domain_permission_attributes: {access_hash: updated_access_hash})
        domain.reload
      end

      context 'Custom Abilities for Domain MEMBER & POWER #edit_topic #comment_tip #like_tip' do
        subject(:ability) { Ability.new(member, domain) }

        let(:tip)       { create(:tip, user: admin) }
        let(:topic)     { create(:topic, user: admin) }

        let(:updated_access_hash) do
          default_permission.merge({
            edit_topic:      { :roles => ["member", "power"] },
            edit_tip:        { :roles => ["member", "power"] },
            comment_tip:     { :roles=>[] },
            like_tip:        {}
          })
        end

        it { expect(domain.domain_permission).to_not be_nil }

        it { should be_able_to(:update, topic) }
        it { should be_able_to(:update, tip) }

        it { should_not be_able_to(:comment, tip) }
        it { should_not be_able_to(:like, tip) }
      end

      context 'Custom Abilities for Domain ADMIN #edit_topic #comment_tip #like_tip' do
        subject(:ability) { Ability.new(admin, domain) }

        let(:tip)       { create(:tip, user: member) }
        let(:topic)     { create(:topic, user: member) }

        let(:updated_access_hash) do
          default_permission.merge({
            edit_topic:      { :roles => ["member", "power"] },
            edit_tip:        { :roles => ["member", "power"] },
            comment_tip:     { :roles=>[] },
            like_tip:        {}
          })
        end

        it { expect(domain.domain_permission).to_not be_nil }

        it { should be_able_to(:update, topic) }
        it { should be_able_to(:update, tip) }

        it { should be_able_to(:comment, tip) }
        it { should be_able_to(:like, tip) }
      end
    end
  end
end
