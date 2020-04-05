require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe V2::InvitationsController, type: :controller do
  let(:user) { create(:user) }

  before do
    user
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create' do
    let(:invitation_attrs) { attributes_for(:invitation) }

    let(:params) do
      {
        data: {
          emails: [FFaker::Internet.email, 'test@test.com'],
          invitable_type: 'User',
          invitable_id: user.id
        }
      }
    end

    context 'when standard create' do
      before do
        post :create, data: params[:data], format: :json
      end

      it { expect(json[:data].first[:type]).to eql 'invitations' }
      it { expect(Invitation.all.pluck(:email)).to include('test@test.com') }

      it 'has a default invitation_type of domain' do
        expect(json[:data].first[:attributes][:invitation_type]).to eql 'domain'
      end
    end

    context 'when member' do
      context 'default' do
        before do
          params[:data][:invitation_type] = 'member'
          params[:data][:options] = { topics: [{ id: 'all' }], users: ['all'] }
          post :create, data: params[:data], format: :json
        end

        it 'creates a member invitation' do
          invitation = Invitation.last
          expect(response).to have_http_status(:created)
          expect(invitation.invitation_type).to eql 'domain'
          expect(invitation.options['topics']).to eql [{ 'id' => 'all' }]
        end

        it { expect(json[:data].first[:attributes][:invitation_type]).to eql 'domain' }
      end
    end

    context 'when guest' do
      context 'when a guest is new' do
        before do
          params[:data][:invitation_type] = 'guest'
          post :create, data: params[:data], format: :json
        end

        it 'creates a guest invitation' do
          expect(response).to have_http_status(:created)
          expect(Invitation.last.invitation_type).to eql 'guest'
        end

        it { expect(json[:data].first[:attributes][:invitation_type]).to eql 'guest' }
      end

      context 'when guest is an existing user' do
        let(:bob) { create(:user, first_name: 'Bob') }

        before do
          bob
          params[:data][:invitation_type] = 'guest'
          params[:data][:emails] = [bob.email]
          post :create, data: params[:data], format: :json
        end

        it 'connects existing user as guest' do
          expect(User.find(bob.id).guest_of?(current_domain)).to be true
          expect(User.find(bob.id).member_of?(current_domain)).to be false
        end

        it { expect(Invitation.last.accepted?).to be true }
      end

      context 'when including groups and topics to belong to' do
        let(:bob) { create(:user, first_name: 'Bob') }
        let(:group) { create(:group, user: user) }
        let(:topic) { create(:topic, user: user) }
        let(:subtopic) { create(:topic, user: user, parent_id: topic.id) }
        let(:tip) { create(:tip, user: user) }
        let(:another_tip) { create(:tip, user: user)}

        context 'when specific topics' do
          before do
            bob
            tip.follow(topic)
            another_tip.follow(subtopic)

            params[:data][:invitation_type] = 'guest'
            params[:data][:emails] = [bob.email]
            params[:data][:options] = {
              groups: [group.id],
              topics: [{ id: topic.id, tips: [tip.id, another_tip.id] }]
            }

            post :create, data: params[:data], format: :json
            @bob = User.find(bob.id)
          end

          it { expect(response).to have_http_status(:created) }

          it 'connects bob to group' do
            expect(@bob.following_groups.pluck(:id)).to include(group.id)
          end

          it 'connects bob to topic' do
            expect(@bob.following_topics.pluck(:id)).to include(topic.id)
          end

          it 'connect bob to subtopic' do
            expect(@bob.following_topics.pluck(:id)).to include(subtopic.id)
          end


          it 'connects bob to tips' do
            bober = @bob

            expect(bober.following_tips.pluck(:id)).to include(tip.id)
            expect(tip.viewable_by?(bober)).to eql true
            expect(bober.following_tips.pluck(:id)).to include(another_tip.id)
            expect(another_tip.viewable_by?(bober)).to eql true
          end

          it 'creates share_settings bob to tips' do
            bober = User.find(bob.id)
            expect(tip.share_settings.where(sharing_object_type: 'User').map(&:sharing_object_id)).to include(bober.id)
          end
        end

        context 'when ALL topics' do
          before do
            bob
            tip.follow(topic)

            params[:data][:invitation_type] = 'guest'
            params[:data][:emails] = [bob.email]
            params[:data][:options] = {
              groups: [group.id],
              topics: [{ id: 'all' }]
            }

            post :create, data: params[:data], format: :json
          end

          it { expect(response).to have_http_status(:created) }
        end
      end

      context 'when including ALL cards for some topics' do
        let(:bob) { create(:user, first_name: 'Bob') }
        let(:topics) { create_list(:topic, 2, user: user) }
        let(:subtopic) { create(:topic, user: user, parent_id: topics.last.id) }
        let(:tips) { create_list(:tip, 4, user: user) }
        let(:subtip) { create(:tip, user: user) }

        before do
          bob
          tips.first(2).each do |tip|
            tip.follow topics.first
          end

          subtip.follow(subtopic)

          tips.last(2).each do |tip|
            tip.follow topics.last
          end

          params[:data][:invitation_type] = 'guest'
          params[:data][:emails] = [bob.email]
          params[:data][:options] = {
            topics: [
              { id: topics.first.id, tips: [tips.first.id] },
              { id: topics.last.id, tips: ['all'] }
            ]
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(User.find(bob.id).following_tips.count).to eql 4 }
        it { expect(User.find(bob.id).following_tips.pluck(:id)).to include(subtip.id) }
      end
    end
  end

  describe 'POST #create share invitation' do
    let(:domain) { create(:domain) }
    let(:topic) { create(:topic) }
    let(:invitation_attrs) { attributes_for(:invitation) }

    let(:params) do
      {
        data: {
          emails: [FFaker::Internet.email],
          invitation_type: 'share',
          invitable_type: 'Topic',
          invitable_id: topic.id
        }
      }
    end

    before do
      post :create, data: params[:data], format: :json
    end

    it { expect(json[:data].first[:attributes][:invitation_type]).to eql 'share' }

    it do
      invitation = Invitation.find_by(id: json[:data][0][:id])
      user = create(:user)
      invitation.connect(user)
      share_setting = ShareSetting.last

      expect(share_setting.sharing_object).to eq(user)
    end
  end

  describe 'POST #create guest invitation' do
    let(:params) do
      {
        data: {
          emails: [FFaker::Internet.email],
          invitation_type: 'guest',
          invitable_type: 'User',
          invitable_id: user.id
        }
      }
    end

    before do
      post :create, data: params[:data], format: :json
    end

    it { expect(response).to have_http_status(:created) }
    it { expect(Invitation.last.invitation_type).to eql 'guest' }
  end

  describe 'POST #create account invitation via domain to existing user' do
    # let(:user) { create(:user) }
    let(:member) { create(:member) }
    let(:domain) { Domain.create(user: user, name: FFaker::Internet.domain_word) }

    let(:params) do
      {
        data: {
          emails: [member.email],
          invitation_type: 'account',
          invitable: user
        }
      }
    end

    before do
      Apartment::Tenant.switch! domain.tenant_name
      post :create, data: params[:data], format: :json
    end

    it { expect(response).to have_http_status(:created) }
    it { expect(json[:data]).to be_an Array }
    it { expect(member.domains.count).to eql(1) }
    it { expect(member.domains.last).to eql(domain) }

    it 'creates correct user connections' do
      invitation = Invitation.last
      user = invitation.user
      expect(user.user_followers.last).to eql(member)
      expect(member.user_followers.last).to eql(user)
    end
  end

  describe 'POST #create for existing member follow_all_settings' do
    let(:member) { create(:member, first_name: 'Bob', email: 'bob@test.com') }
    let(:domain) { create(:domain, user: user, name: 'test-domain') }

    let(:params) do
      {
        data: {
          emails: [member.email],
          invitation_type: 'account',
          invitable: user
        }
      }
    end

    before do
      Sidekiq::Testing.inline! do
        member # Needs to exist already
        Apartment::Tenant.switch! domain.tenant_name
        post :create, data: params[:data], format: :json
      end
    end

    describe 'test the settings only' do
      it 'sets follows_all_settings correctly' do
        new_member = User.find(member.id)
        expect(new_member.user_profile.follow_all_topics).to be true
        expect(new_member.user_profile.follow_all_domain_members).to be true
      end
    end

    describe 'test if actually following topics' do
      let(:topic_list) { create_list(:topic, 2) }

      before do
        Sidekiq::Testing.inline! do
          topic_list
        end
      end

      it 'follows_all_topics' do
        Apartment::Tenant.switch 'public' do
          expect(Topic.count).to eq 0
        end

        Apartment::Tenant.switch 'test-domain' do
          expect(Topic.count).to eq 2
        end

        new_member = User.find(member.id)
        expect(new_member.following_topics.count).to eq 2
      end
    end
  end

  describe 'POST request_invitation' do
    let(:params) do
      {
        data: {
          email: 'bob@test.com',
          first_name: 'Bob',
          last_name: 'Evans'
        }
      }
    end

    before do
      request.headers['Authorization'] = nil
      post :request_invitation, data: params[:data], format: :json
    end

    it { expect(response).to have_http_status(:created) }
    it { expect(json[:data][:attributes][:user_id]).to eql current_domain.user_id }
    it { expect(json[:data][:attributes][:first_name]).to eql 'Bob' }
    it { expect(json[:data][:attributes][:email]).to eql 'bob@test.com' }
    it { expect(json[:data][:attributes][:state]).to eql 'requested' }
  end

  # describe 'GET #connect account invitation sent via domain' do
  #   let(:member) { create(:member) }
  #   let(:domain) { Domain.create(user: member, name: FFaker::Internet.domain_word) }
  #   let(:invitation) do
  #     Invitation.create(
  #       invitation_type: 'account',
  #       invitable: member,
  #       email: user.email,
  #       user: member
  #     )
  #   end

  #   before do
  #     Apartment::Tenant.switch! domain.tenant_name
  #     get :connect, { id: invitation.invitation_token }, format: :json
  #   end

  #   it { expect(response).to have_http_status(:success) }
  #   it { expect(json[:data][:id]).to eql("#{user.id}") }
  #   it { expect(user.domains.count).to eql(2) }
  #   it { expect(user.domains.last).to eql(domain) }
  # end
end
