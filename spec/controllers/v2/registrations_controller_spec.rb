require 'rails_helper'
require 'sidekiq/testing'

describe V2::RegistrationsController do
  let(:user_attributes) { attributes_for(:user) }

  before do
    request.host = 'api.tiphive.dev'
  end

  let(:params) do
    {
      user: {
        email: user_attributes[:email],
        password: user_attributes[:password],
        password_confirmation: user_attributes[:password_confirmation],
        username: user_attributes[:username],
        first_name: user_attributes[:first_name],
        last_name: user_attributes[:last_name]
      }
    }
  end

  context 'when registering without an invitation' do
    context 'when domain requires invitation (default)' do
      before do
        post :create, user: params[:user], format: :json
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context 'when domain is open' do
      let(:domain) { create(:domain, join_type: 'open') }

      before do
        Apartment::Tenant.switch!(domain.tenant_name)
        post :create, user: params[:user], format: :json
      end

      it { expect(response).to have_http_status(:created) }
    end
  end

  context 'when coming from an invitations' do
    let(:test_domain) { create(:domain, tenant_name: 'test_domain') }

    let(:bob) { create(:user, first_name: 'Bob') }
    let(:invitation) { create(:invitation, user: bob, email: params[:user][:email]) }
    let(:domain_invitation) { create(:domain_invitation, user: bob, email: params[:user][:email]) }

    context 'when account invitation' do
      before do
        Apartment::Tenant.switch!('public')

        post :create, user: params[:user], invitation_token: invitation.invitation_token
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(User.last.domain_memberships.count).to eql 0 }
    end

    context 'when domain invitation' do
      let(:topic) { create(:topic, user: bob, title: 'Topic One') }
      let(:topic2) { create(:topic, user: bob, title: 'Topic Two') }

      let(:member_invitation) do
        # Invitation from Bob to Mary as a member
        create(
          :domain_invitation,
          user: bob,
          invitation_type: 'domain',
          invitable: current_domain,
          email: 'mary@test.com',
          options: { topics: [{ id: 'all' }], users: ['all'] }
        )
      end

      context 'when invitation set to follow all' do
        before do
          Apartment::Tenant.switch! test_domain.tenant_name

          bob
          topic
          topic2

          params[:user][:email] = 'mary@test.com'
          params[:user][:first_name] = 'Mary'

          post :create, user: params[:user], invitation_token: member_invitation.invitation_token
        end

        it 'creates a guest of current domain' do
          expect(User.find_by(email: 'mary@test.com').member_of?(member_invitation.invitable)).to be true
        end

        it 'creates a proper domain membership' do
          domain_memberships = User.find_by(email: 'mary@test.com').domain_memberships
          expect(domain_memberships.count).to eql 1
          expect(domain_memberships.last.invitation_id).to eql member_invitation.id
        end

        it 'follows all topics and users' do
          mary = User.find_by(email: 'mary@test.com')

          expect(mary.following_users.count).to eql current_domain.users.count
          expect(mary.following_topics.count).to eql 2
        end

        it 'does not get topics shared with them' do
          mary = User.find_by(email: 'mary@test.com')

          expect(topic.share_settings.where(sharing_object_type: 'User', sharing_object_id: mary.id)).to be_empty
        end
      end

      context 'when invitation set to follow one topic' do
        before do
          topic2
          member_invitation.update_attribute(:options, topics: [{ id: topic.id }])

          params[:user][:email] = 'mary@test.com'
          params[:user][:first_name] = 'Mary'

          post :create, user: params[:user], invitation_token: member_invitation.invitation_token
        end

        it 'follows all correct topic' do
          user = User.find_by(email: 'mary@test.com')
          expect(user.following_topics).to include topic
          expect(user.following_topics).to_not include topic2
        end
      end
    end

    context 'when guest invitation' do
      let(:guest_invitation) do
        # Invitation from Bob to Mary as a guest
        create(:guest_invitation, user: bob, invitation_type: 'guest', email: 'mary@test.com')
      end

      before do
        params[:user][:email] = 'mary@test.com'
        params[:user][:first_name] = 'Mary'
      end

      context 'when no selections of what to share' do    
        before do
          post :create, user: params[:user], invitation_token: guest_invitation.invitation_token
        end

        it 'creates a guest of current domain' do
          expect(User.find_by(email: 'mary@test.com').guest_of?(guest_invitation.invitable)).to be true
        end

        it 'creates a proper domain membership' do
          domain_memberships = User.last.domain_memberships
          expect(domain_memberships.count).to eql 1
          expect(domain_memberships.last.invitation_id).to eql guest_invitation.id
        end
      end

      context 'when invited to follow some cards' do
        let(:topic) { create(:topic, user: bob) }
        let(:tips) { create_list(:tip, 3, user: bob) }
        
        before do
          tips.each { |tip| tip.follow(topic) }
          guest_invitation.options = { topics: [{ id: topic.id, tips: ["#{tips[0].id}", tips[1].id] }] }
          guest_invitation.save

          post :create, user: params[:user], invitation_token: guest_invitation.invitation_token
        end

        it 'shares selected topic' do
          user_id = json[:data][:id]
          expect(ShareSetting.find_by(
            shareable_object_id: topic,
            shareable_object_type: 'Topic',
            sharing_object_id: user_id,
            sharing_object_type: 'User'
          )).to_not be_nil
        end

        it 'shares all selected cards with user' do
          user_id = json[:data][:id]
          [0,1].each do |i|
            expect(ShareSetting.find_by(
              shareable_object_id: tips[i].id,
              shareable_object_type: 'Tip',
              sharing_object_id: user_id,
              sharing_object_type: 'User'
            )).to_not be_nil
          end
        end

        it 'follows selected cards' do
          user_id = json[:data][:id]
          [0,1].each do |i|
            expect(Follow.find_by(
              followable_id: tips[i].id,
              followable_type: 'Tip',
              follower_id: user_id,
              follower_type: 'User'
            )).to_not be_nil
          end
        end

        it 'does not share cards not selected with user' do
          user_id = json[:data][:id]
          expect(ShareSetting.find_by(
            shareable_object_id: tips[2].id,
            shareable_object_type: 'Tip',
            sharing_object_id: user_id,
            sharing_object_type: 'User'
          )).to be_nil
        end
      end

      context 'when allowing ALL tips within a topic' do
        let(:sally) { create(:user, first_name: 'Sally') }
        let(:topic) { create(:topic, user: bob) }
        let(:tip_list) { create_list(:tip, 2, user: bob) }
        let(:private_tip) { create(:tip, share_public: false, user: sally) }

        let(:guest_invitation) do
          # Invitation from Bob to Mary as a guest
          create(
            :guest_invitation,
            user: bob,
            invitation_type: 'guest',
            email: 'mary@test.com',
            options: {
              topics: [{ id: topic.id, tips: ['all'] }],
              users: ['all']
            }
          )
        end

        before do
          tip_list.each { |tip| tip.follow(topic) }
          private_tip.follow(topic)
          params[:user][:email] = 'mary@test.com'
          params[:user][:first_name] = 'Mary'

          post :create, user: params[:user], invitation_token: guest_invitation.invitation_token
        end

        it 'follows topic' do
          expect(User.find_by(email: 'mary@test.com').following_topics).to include topic
        end

        it 'follows all tips except private_tip' do
          tips = User.find_by(email: 'mary@test.com').following_tips
          expect(tips.count).to eql 2
          expect(tips).to_not include private_tip
        end
      end
    end
  end

  context 'when invitation token is not found' do
    before do
      post :create, user: params[:user]
    end

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'POST #create follow_all_settings' do
    let(:existing_user) { create(:user, first_name: 'Bob') }
    let(:user_list) { create_list(:user, 3) }
    let(:topic_list) { create_list(:topic, 2, user: existing_user) }

    context 'when domain is public' do
      before do
        Sidekiq::Testing.inline! do
          Apartment::Tenant.switch! 'public'
          post :create, user: params[:user], format: :json
        end
      end

      it { expect(response).to have_http_status(:created) }

      context 'when testing settings' do
        it 'does not change settings' do
          expect(User.find(json[:data][:id]).user_profile.follow_all_topics).to be false
          expect(User.find(json[:data][:id]).user_profile.follow_all_domain_members).to be false
        end
      end

      context 'when testing topic connections' do
        before do
          Sidekiq::Testing.inline! do
            topic_list
          end
        end

        it { expect(User.find(json[:data][:id]).following_topics.count).to eq 0 }
      end
    end

    context 'when domain is not public' do
      let(:domain) { create(:domain, join_type: 'open') }

      context 'when testing settings' do
        before do
          Sidekiq::Testing.inline! do
            Apartment::Tenant.switch!(domain.tenant_name)
            post :create, user: params[:user], format: :json
          end
        end

        it { expect(response).to have_http_status(:created) }

        it 'sets follow alls to true' do
          expect(User.find(json[:data][:id]).user_profile.follow_all_topics).to be true
          expect(User.find(json[:data][:id]).user_profile.follow_all_domain_members).to be true
        end
      end

      context 'when testing topic connections' do
        before do
          Sidekiq::Testing.inline! do
            Apartment::Tenant.switch!(domain.tenant_name)
            topic_list
            post :create, user: params[:user], format: :json
          end
        end

        it { expect(User.find(json[:data][:id]).following_topics.count).to eq 2 }
      end

      context 'when testing user connections' do
        before do
          Sidekiq::Testing.inline! do
            Apartment::Tenant.switch!(domain.tenant_name)

            user_list.each do |user|
              user.join(domain)
            end

            post :create, user: params[:user], format: :json
          end
        end

        it { expect(User.find(json[:data][:id]).following_users.count).to eq(domain.members.count - 1) }
      end
    end
  end

  describe 'POST #create Block Spammers' do
    context 'when qq.com' do
      before do
        params[:user][:email] = 'spammer@qq.com'
        Apartment::Tenant.switch! 'public'

        post :create, user: params[:user], format: :json
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context 'when sina.com' do
      before do
        params[:user][:email] = 'spammer@sina.com'
        Apartment::Tenant.switch! 'public'

        post :create, user: params[:user], format: :json
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end
  end
end
