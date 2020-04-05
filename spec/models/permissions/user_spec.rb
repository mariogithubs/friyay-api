require 'rails_helper'
require 'cancan/matchers'

describe User do
  # TODO: Add tests for groups
  describe '#abilities' do
    let(:tip) { user.tips.create(title: FFaker::Lorem.words(rand(1..4)).join(' ').titleize) }
    let(:topic) { user.topics.create(title: FFaker::Lorem.words(rand(1..4)).join(' ').titleize) }

    describe '#can abilities' do
      subject(:ability) { Ability.new(user, domain) }

      context 'default abilities when is domain member' do
        let(:user) { domain.users.first }
        let(:domain) { create(:domain) }

        it { should be_able_to(:create, Tip) }
        it { should be_able_to(:comment, Tip) }
        it { should be_able_to(:like, Tip) }

        it { should be_able_to(:create, Topic) }

        it { should be_able_to(:update, tip) }
        it { should be_able_to(:destroy, tip) }

        it { should be_able_to(:update, topic) }
        it { should be_able_to(:destroy, topic) }
      end
    end

    describe '#cannot abilities' do
      subject(:ability) { Ability.new(member2, domain) }

      before do
        member.join(domain)
        member2.join(domain)
      end

      context 'default abilities when is domain member but not owner of resources' do
        let(:domain) { create(:domain) }
        let(:user) { domain.users.first }
        let(:member) { create(:member) }
        let(:member2) { create(:member2) }

        it { should be_able_to(:update, tip) }
        xit { should_not be_able_to(:destroy, tip) }

        it { should_not be_able_to(:update, topic) }
        it { should_not be_able_to(:destroy, topic) }
      end
    end

    describe '#custom abilities' do
      let(:group) { create(:group) }
      let(:member3) { create(:user) }
      let(:domain) do
        d = Domain.find_by(tenant_name: Apartment::Tenant.current)

        d.domain_permission_attributes = {
          access_hash: {
            create_topic:     { roles: ['member'] },
            edit_topic:       {},
            destroy_topic:    {},
            create_tip:       { roles: ['member'] },
            edit_tip:         {},
            destroy_tip:      {},
            like_tip:         { roles: ['member'] },
            comment_tip:      {},
          }
        }
        d.save
        d
      end
      let(:user) { domain.users.first }
      let(:member) { create(:member) }
      let(:member2) { create(:member2) }

      subject(:ability) { Ability.new(ability_user, domain) }

      before do
        member.join(domain)
        member2.join(domain)
      end

      context 'abilities when is domain member' do
        let(:ability_user) { member2 }

        it { should_not be_able_to(:update, tip) }
        it { should_not be_able_to(:comment, tip) }
      end

      context 'abilities when is domain member, checking reverse abilities' do
        let(:ability_user) { user }

        it { should be_able_to(:update, tip) }
      end

      context 'abilities when is domain admin' do
        let(:ability_user) do
          member3.add_role 'admin', domain
          member3
        end

        it { should be_able_to(:update, tip) }
      end

      context 'hive abilities' do
        let(:ability_user) do
          member3.add_role 'admin', domain
          member3
        end

        let(:hive) do
          topic = create(:topic)

          topic.topic_permission_attributes = {
            access_hash: {
              create_topic:     { roles: ['member'] },
              edit_topic:       {},
              destroy_topic:    {},
              create_tip:       { roles: ['member'] },
              edit_tip:         {},
              destroy_tip:      {},
              like_tip:         { roles: ['member'] },
              comment_tip:      { roles: ['member'] },
            }
          }

          topic.save
          topic
        end

        before do
          tip.follow hive
        end

        it { should be_able_to(:update, tip) }
        it do
          member3.add_role 'admin', topic
          member3.can? :update, tip
        end
      end
    end
  end
end
