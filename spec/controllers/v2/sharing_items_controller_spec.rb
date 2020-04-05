require 'rails_helper'

RSpec.describe V2::SharingItemsController, type: :controller do
    let(:user) { create(:user, first_name: 'Wally') }

    before do
      user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
      request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
      request.host = 'api.tiphive.test'
      end

    describe 'GET #index' do
      let(:tip) { create(:tip, user_id: user.id) }
      let(:bob) { create(:user, first_name: 'bob', last_name: 'test') }
      let(:groups) { create_list(:group, 2, user_id: bob.id) }

      context 'when a member' do
        before do
          bob
          bob.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
          groups

          user.follow(groups[0])
          user.follow bob
       
          allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search).to receive(:results).and_return(User.all + Group.all)
          get :index, resources: 'User,Group', format: :json
        end

        it 'returns all users' do
          # 3 users: Admin from setup, Wally as current_user, Bob
          # Currently, we allow people to see themselves in the list
          expect(json[:data].count { |ss| ss[:attributes][:resource_type] == 'users' }).to eql(3)
        end

        it 'returns only groups that the current user is a member of' do
          expect(json[:data].count { |ss| ss[:attributes][:resource_type] == 'groups' }).to eql(1)
        end
      end

      context 'when a member and domain is public' do
        before do
          bob

          Apartment::Tenant.switch!('public')
          allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search).to receive(:results).and_return(User.all)
          get :index, resources: 'User,Group', format: :json
        end

        it 'does not return all users if domain is public' do
          # 3 users: Admin from setup, Wally as current_user, Bob
          # on public, Wally should only see himself
          expect(json[:data].count { |ss| ss[:attributes][:resource_type] == 'users' }).to eql(1)
        end
      end

      context 'when a guest' do
        before do
          user.leave(current_domain)
          user.join(current_domain, as: 'guest')

          bob
          groups
          allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search).to receive(:results).and_return(User.all + Group.all)

          user.follow(groups[0])
          user.follow bob
          get :index, resources: 'User,Group', format: :json
        end

        it 'returns resources followed by user' do
          expect(json[:data].count { |ss| ss[:attributes][:resource_type] == 'users' }).to eql(1)
          expect(json[:data].count { |ss| ss[:attributes][:resource_type] == 'groups' }).to eql(1)
        end
      end
    end
end
