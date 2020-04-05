require 'rails_helper'

describe Domain do
  include LinkHelpers

  it { should respond_to(:name) }
  it { should respond_to(:tenant_name) }
  it { should respond_to(:user_id) }
  it { should respond_to(:join_type) }
  it { should respond_to(:email_domains) }
  it { should respond_to(:allow_invitation_request) }
  it { should respond_to(:color) }

  describe 'enum types' do
    it { expect(described_class.join_types.count).to eql 2 }
    it { should respond_to(:invitation_required!) }
    it { should respond_to(:open!) }
  end

  describe 'associations' do
    it { is_expected.to belong_to :user }
  end

  it 'has a valid factory' do
    expect(build(:domain)).to be_valid
  end

  describe 'invalid cases' do
    let(:domain1) { create(:domain, name: 'Test Domain', user_id: 1) }
    let(:same_name) { build(:domain, name: 'Test Domain', tenant_name: 'blah') }
    let(:same_lowercase_name) { build(:domain, name: 'test domain', tenant_name: 'blah') }
    let(:no_name) { build(:domain, name: nil) }
    let(:same_tenant_name) { build(:domain, name: 'Different', tenant_name: 'test-domain') }
    let(:non_standard_tenant_name) { build(:domain, name: 'Different', tenant_name: 'A Nother Tenant') }

    before do
      domain1
    end

    it { expect(same_name).to_not be_valid }
    it { expect(same_lowercase_name).to_not be_valid }
    it { expect(no_name).to_not be_valid }
    it { expect(same_tenant_name).to_not be_valid }
    it { expect(non_standard_tenant_name).to be_valid }
  end

  describe 'automated processes' do
    let(:domain) { create(:domain, user: create(:user)) }

    it 'has its creator as a follower' do
      expect(domain.users.pluck(:id)).to include domain.user_id
    end

    it 'created a tenant' do
      Apartment::Tenant.switch! domain.tenant_name

      expect(Apartment::Tenant.current).to eql domain.tenant_name
    end
  end

  describe '#email_acceptable?(email)' do
    let(:domain) { build(:domain) }

    before do
      domain.email_domains = ['gmail.com', 'tiphive.com']
    end

    it { expect(domain.email_acceptable?('test@gmail.com')).to eql true }
    it { expect(domain.email_acceptable?('test@apple.com')).to eql false }
  end

  describe 'add slack team and channels for domain' do
    let(:tip) { create(:tip) }
    let(:slack_links) { build_test_slack_links }
    let(:domain) { described_class.find_by tenant_name: Apartment::Tenant.current }
    let(:slack_team_data) do
      {
        team_id: 'T029L9M6A',
        team_name: 'tiphive',
        scope: 'identify,bot,commands,incoming-webhook,channels:history,channels:read',
        access_token: 'xoxp-2326327214-16623995793-40779161632-83175d75b2',
        incoming_webhook: {
          channel: '#development',
          channel_id: 'C029M7AN8',
          configuration_url: 'https://tiphive.slack.com/services/B18KQUJSX',
          url: 'https://hooks.slack.com/services/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'
        },
        bot: {
          bot_user_id: 'U16BQHUG6',
          bot_access_token: 'xoxb-40398606550-k363o2SDxsQWtGOOCcWL3Mtt'
        }
      }
    end

    before do
      domain.add_slack_team(slack_team_data)
      SlackChannelWorker.drain

      paragraph = FFaker::Lorem.paragraph + ' '
      paragraph += slack_links.join(' ')

      tip.update_attributes body: paragraph

      SlackMessageWorker.drain
    end

    it do
      slack_team = domain.slack_teams.last

      expect(domain.slack_teams.count).to eql 1
      expect(slack_team.slack_channels.count).to be >= 1

      expect(SlackLink.last.messages).to eq(I18n.t('slack.dummy_messages'))
    end
  end

  describe '#add_guest' do
    let(:domain) { described_class.find_by tenant_name: Apartment::Tenant.current }
    let(:bob) { create(:user, first_name: 'Bob') }

    it { expect { domain.add_guest(bob) }.to change { Role.count }.from(0).to(1) }
  end
end
