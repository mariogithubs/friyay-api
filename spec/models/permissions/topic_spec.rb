require 'rails_helper'
require 'cancan/matchers'

describe Topic do
  let(:domain) { Domain.find_by_tenant_name(Apartment::Tenant.current) }

  describe '#abilities' do
    let(:default_permission) do
      {
        :create_topic=>{:roles=>["member"]},
        :edit_topic=>{:roles=>['member']},
        :destroy_topic=>{},
        :create_tip=>{:roles=>["member"]},
        :edit_tip=>{},
        :destroy_tip=>{},
        :like_tip=>{:roles=>["member"]},
        :comment_tip=>{:roles=>["member"]}
      }
    end

    before :all do
      # domain
      # Apartment::Tenant.switch!(domain.tenant_name)
    end

    describe 'default permissions upon create' do
      context 'default permissions should apply automatically for a topic in public domain' do
        # let(:domain) { build(:domain) }
        let(:topic)  { create(:topic) }

        it { expect(domain).to_not be_nil }
        it { expect(topic.topic_permission).to eq nil }
        it { expect(topic.permission).to eq({}) }
      end

      context 'default permissions should apply automatically for a topic in new private domain' do
        # let(:domain) { build(:domain) }
        let(:topic)  { create(:topic) }

        it { expect(topic.topic_permission).to eq nil }
        it { expect(topic.permission).to eq({}) }
      end
    end

    describe 'test default abilities for topic' do
      let(:admin) { create(:user) }
      let(:member) { create(:user) }

      let!(:domain)     { create(:domain, user: admin) }
      let!(:hive_admin) { create(:user) }
      let!(:tip)        { create(:tip) }
      let!(:topic)      { create(:topic, user: hive_admin) }

      before do
        member.join(domain)
      end

      context 'Private Domain MEMBER abilities' do
        subject(:ability) { Ability.new(member, domain, topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }
        it { should be_able_to(:update, tip) }

        xit { should_not be_able_to(:destroy, tip) }

        it { should_not be_able_to(:update, domain) }
      end

      context 'Private Domain HIVE ADMIN abilities' do
        subject(:ability) { Ability.new(hive_admin, domain, topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should_not be_able_to(:update, domain) }
      end

      context 'Private Domain DOMAIN ADMIN abilities' do
        subject(:ability) { Ability.new(admin, domain, topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should be_able_to(:update, domain) }
      end
    end

    describe 'test custom abilities for topic' do
      let(:admin) { create(:user) }
      let(:member) { create(:user) }

      let!(:domain)     { create(:domain, user: admin) }
      let!(:hive_admin) { create(:user) }
      let!(:tip)        { create(:tip) }
      let!(:topic)      { create(:topic, user: hive_admin) }

      let(:updated_access_hash) do
        default_permission.merge({
          comment_tip:     { :roles=>[] },
          create_tip:      {},
          like_tip:        {}
        })
      end

      before do
        member.join(domain)
        tip.follow(topic)

        topic.update_attributes(topic_permission_attributes: {access_hash: updated_access_hash})
        topic.reload
      end

      context 'Private Domain MEMBER abilities' do
        subject(:ability) { Ability.new(member, domain, topic) }

        it { should_not be_able_to(:create, Tip) }

        it { should_not be_able_to(:like, tip) }
        it { should_not be_able_to(:comment, tip) }

        it { should_not be_able_to(:update, tip) }
        it { should_not be_able_to(:destroy, tip) }
      end

      context 'Domain permission supercedes hive when domain disallows any access' do
        let(:updated_access_hash) do
          default_permission.merge({
            edit_topic:      { :roles=>["member"] },
            edit_tip:        {}
          })
        end

        subject(:ability) { Ability.new(member, domain, topic) }

        it { should_not be_able_to(:update, topic) }
        it { should_not be_able_to(:update, tip) }
      end

      context 'Domain permission does not supercedes hive when domain allows any access' do
        let(:updated_access_hash) do
          default_permission.merge({
            edit_topic:      { :roles=>["member"] }
          })
        end

        let(:domain_access_hash) do
          default_permission.merge({
            edit_topic:      { :roles=>["member"] },
            edit_tip:        { :roles=>["member"] }
          })
        end

        subject(:ability) { Ability.new(member, domain, topic) }

        before(:each) do
          domain.update_attributes(domain_permission_attributes: {access_hash: domain_access_hash})
          domain.reload
        end

        it { should     be_able_to(:update, topic) }
        it { should_not be_able_to(:update, tip) }
      end

      context 'Private Domain HIVE ADMIN abilities' do
        subject(:ability) { Ability.new(hive_admin, domain, topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }
      end

      context 'Private Domain DOMAIN ADMIN abilities' do
        subject(:ability) { Ability.new(admin, domain, topic) }

        it { should be_able_to(:create, Tip) }

        it { should be_able_to(:like, tip) }
        it { should be_able_to(:comment, tip) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }
      end
    end
  end
end
