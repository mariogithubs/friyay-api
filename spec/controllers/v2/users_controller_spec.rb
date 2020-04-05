require 'rails_helper'

describe V2::UsersController do
  let(:user) { User.first || create(:user) }

  before do
    user.join(current_domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:mary) { create(:user, first_name: 'Mary') }
    let(:sally) { create(:user, first_name: 'Sally') }
    let(:users) { [bob, mary] }
    let(:users_to_follow) { create_list(:user, 2) }

    context 'when no filter and defaults to following' do
      before do
        users_to_follow.each { |user_to_follow| user_to_follow.join(current_domain) }
        users.each { |user| user.join(current_domain) }
        users_to_follow.each { |user_to_follow| user.follow(user_to_follow) }

        get :index, format: :json
      end

      it { expect(json[:data].count).to eql(2) }
      it { expect(json[:meta].keys).to include(:total_pages) }
    end

    context 'when there are inactive users' do
      before do
        bob.join(current_domain)
        mary.join(current_domain)
        membership = MembershipService.new(current_domain, bob)
        membership.leave!

        get :index, format: :json
      end

      it 'defaults to returning only active users' do
        it { expect(DomainMember.active.count).to eql 2 }
        it { expect(json[:data].count).to eql 2 }
      end
    end

    context 'when asking for inactive' do
      before do
        bob.join(current_domain)
        mary.join(current_domain)
        sally.join(current_domain)
        membership = MembershipService.new(current_domain, bob)
        membership.leave!

        get :index, filter: { is_active: 'false' }, format: :json
      end

      it { expect(DomainMember.active.count).to eql 3 }
      it { expect(json[:data].count).to eql 1 }
      it { expect(json[:data].first[:attributes][:first_name]).to eql bob.first_name }
    end

    context 'when asking for all' do
      before do
        bob.join(current_domain)
        mary.join(current_domain)
        user.join(current_domain)
        membership = MembershipService.new(current_domain, bob)
        membership.leave!

        get :index, filter: { users: 'all', is_active: 'all' }, format: :json
      end

      it { expect(json[:data].count).to eql(DomainMember.count - 1) }
    end

    context 'when filtering followers' do
      before do
        users_to_follow.each { |user_to_follow| user_to_follow.join(current_domain) }
        users.each { |user| user.join(current_domain) }
        users.each { |user_follower| user_follower.follow(user) }

        get :index, filter: { users: 'followers' }, format: :json
      end

      it { expect(json[:data].count).to eql(2) }
    end

    context 'when filtering within group' do
      let(:group) { create(:group) }

      before do
        bob.join(current_domain)
        bob.follow(group)
        user.follow(group)

        users_to_follow.each { |user_to_follow| user_to_follow.join(current_domain) }
        users_to_follow.each { |user_to_follow| user_to_follow.follow(group) }
        users_to_follow.each { |user_to_follow| user.follow(user_to_follow) }

        get :index, filter: { within_group: group.id }, format: :json
      end

      it { expect(json[:data].count).to eql 3 }
    end

    context 'when filtering by following within group' do
      let(:group) { create(:group) }

      before do
        bob.join(current_domain)
        bob.follow(group)
        user.follow(group)

        users_to_follow.each { |user_to_follow| user_to_follow.join(current_domain) }
        users_to_follow.each { |user_to_follow| user_to_follow.follow(group) }
        users_to_follow.each { |user_to_follow| user.follow(user_to_follow) }

        get :index, filter: { users: 'following', within_group: group.id }, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end

    context 'when filtering with ALL' do
      before do
        users.each { |user| user.join current_domain }

        get :index, filter: { users: 'all' }, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end

    context 'when filtering with ALL when user is guest' do
      before do
        user.leave(current_domain)
        user.join(current_domain, as: 'guest')
        users.each { |user| user.join current_domain }

        get :index, filter: { users: 'all' }, format: :json
      end

      it { expect(json[:data].count).to eql 0 }
    end

    context 'when filtering with ALL and domain is public' do
      before do
        Apartment::Tenant.switch! 'public'
        users
        users_to_follow.each { |uf| user.follow(uf) }

        get :index, filter: { users: 'all' }, format: :json
      end

      it { expect(User.count).to eql(users.count + users_to_follow.count + 1) }
      it { expect(json[:data].count).to eql users_to_follow.size }
    end

    context 'when user is removed from hive' do
      let(:domain_one) { create(:domain, name: 'Domain One', user: mary) } 
      before do
        bob.join(domain_one)
        bob.join(current_domain)
        bob.leave(current_domain)
        
        get :index,filter: { users: 'all' }, format: :json
      end
      it { expect(json[:data].count).to eql 0 }
    end

  end

  describe 'GET #show' do
    context 'when given an id' do
      before :each do
        get :show, id: user, format: :json
      end

      it { expect(response).to have_http_status(:ok) }

      it 'returns user' do
        expect(json[:data][:attributes][:first_name]).to eql user.first_name
      end
    end

    context 'when given a username' do
      before do
        get :show, id: user.username, format: :json
      end

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'PUT/PATCH #update' do
    context 'when successfully updated' do
    end
  end

  describe 'POST #follow' do
    let(:bob) { create(:user, first_name: 'Bob') }

    before do
      bob.join(current_domain)

      post :follow, id: bob.id, format: :json
    end

    it { expect(response).to have_http_status(:success) }
    it { expect(json[:data][:id]).to eql bob.id.to_s }
    it { expect(bob.user_followers.pluck(:id)).to include(user.id) }
  end

  describe 'POST #unfollow' do
    let(:bob) { create(:user, first_name: 'Bob') }

    before do
      user.follow(bob)

      post :unfollow, id: bob.id, format: :json
    end

    it { expect(response).to have_http_status(:success) }
    it { expect(json[:data]).to be_empty }
    it { expect(bob.user_followers.pluck(:id)).to_not include(user.id.to_s) }
  end
end
