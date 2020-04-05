require 'rails_helper'
require 'cancan/matchers'

describe User do
  describe 'associations' do
    it { is_expected.to have_many :domains }
    it { is_expected.to have_many(:tips) }
    it { is_expected.to have_many(:questions) }
    it { is_expected.to have_many(:topics) }
    it { is_expected.to have_many(:groups) }
    # it { is_expected.to have_many(:contexts) }
  end

  it 'has a valid factory' do
    expect(build(:user)).to be_valid
  end

  let(:user) { build(:user) }
  let(:bob) { create(:user) }

  subject { user }

  it { should respond_to(:email) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }

  it { should be_valid }
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email) }
  it { should validate_confirmation_of(:password) }
  it { should allow_value('domain@example.com').for(:email) }

  describe '#follow_resources' do
    context 'when Topic' do
      let(:topic_1) { create(:topic) }
      let(:topic_2) { create(:topic) }
      let(:subtopic) { create(:topic, parent_id: topic_2.id) }

      context 'when specific ids' do
        before do
          topic_2 # make sure to create topic 2 so test is valid
          bob.follow_resources('Topic', [topic_1.id])
        end

        it 'follows the correct topics' do
          expect(bob.following_topics.map(&:id)).to include topic_1.id
          expect(bob.following_topics.map(&:id)).to_not include topic_2.id
        end
      end

      context 'when all' do
        before do
          topic_1
          topic_2
          subtopic
          bob.follow_resources('Topic', ['all'])
        end

        it 'follows the correct topics' do
          expect(bob.following_topics.map(&:id)).to include topic_1.id
          expect(bob.following_topics.map(&:id)).to include topic_2.id
          expect(bob.following_topics.map(&:id)).to include subtopic.id
        end
      end
    end

    context 'when Group' do
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }

      before do
        bob.follow_resources('Group', [group_1.id])
      end

      it 'follows the correct groups' do
        expect(bob.following_groups.map(&:id)).to include group_1.id
        expect(bob.following_groups.map(&:id)).to_not include group_2.id
      end
    end
  end

  describe '#join(resource)' do
    # TODO: Do we need this? the controller specs should cover this
    # let(:domain) { create(:domain, user: create(:user)) }
    # it 'does something' do
    #   user.save
    #   user.join(domain)
    #   bob.join(domain)

    #   Apartment::Tenant.switch domain.tenant_name do
    #     FactoryGirl.create_list(:topic, 2, user: user)
    #     Topic.all.each do |t|
    #       bob.follow(t)
    #     end
    #     bob.follow(user)
    #   end

    #   expect(domain.domain_members.pluck(:id)).to include(user.id)

    #   Apartment::Tenant.switch domain.tenant_name do
    #     expect(bob.follows.count).to eql(3)
    #   end
    # end
  end

  describe '#leave(resource)' do
    let(:domain) { create(:domain) }
    let(:domain_membership) { DomainMembership.create(user_id: bob.id, domain_id: domain.id) }

    it 'reduces domain_memberships' do
      bob
      domain
      domain_membership

      Apartment::Tenant.switch domain.tenant_name do
        FactoryGirl.create_list(:topic, 2, user: user)
        Topic.all.each do |t|
          bob.follow(t)
        end
      end

      bob.leave(domain_membership.domain)
      expect(domain.domain_members.pluck(:id)).to_not include(bob.id)
    end
  end

  describe '#update' do
    let(:bob) { create(:user, password: '12345678', password_confirmation: '12345678') }

    it 'updates email with current password' do
      bob.update_attributes(email: 'dhuparpayal@gmail.com', current_password: '12345678')
      expect(bob.errors.full_messages).to_not include('Current password is invalid')
      bob.reload
      expect(bob.email).to eql('dhuparpayal@gmail.com')
    end

    it 'updates password with current password' do
      bob.update_attributes(password: '012345678', password_confirmation: '012345678', current_password: '12345678')
      expect(bob.errors.full_messages).to_not include('Current password is invalid')
      expect(bob.errors.full_messages).to_not include('Password confirmation doesn\'t match Password')
    end

    it 'updates first_name' do
      name = FFaker::Name.first_name
      bob.update_attributes(first_name: name)
      expect(bob.errors.count).to eql(0)
      bob.reload
      expect(bob.first_name).to eql(name)
    end
  end

  describe '#guest_domains' do
    let(:guest_domain) { create(:domain, tenant_name: 'guest_domain', user: user) }
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:current_domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

    before do
      bob.join(current_domain)
      guest_domain.add_guest(bob)
    end

    it { expect(bob.guest_domains).to include guest_domain }
    it { expect(bob.guest_domains).to_not include current_domain }
  end

  describe '#email_domain' do
    # should return gmail.com if given anthony@gmail.com
  end
end
