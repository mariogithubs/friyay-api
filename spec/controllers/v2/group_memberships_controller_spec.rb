require 'rails_helper'

RSpec.describe V2::GroupMembershipsController, type: :controller do
  let(:user) { create(:user) }
  let(:group) { create(:group, user_id: user.id) }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  let(:user_list) { create_list(:user, 2) }
  let(:bob) { create(:user, first_name: 'Bob') }
  let(:mary) { create(:user, first_name: 'Mary') }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, group_id: group.id, format: :json
      expect(response).to have_http_status(:success)
      expect(json[:data].count).to be > 0
    end

    context 'when there are other followers' do
      before do
        bob.follow(group)
        get :index, group_id: group.id, format: :json
      end

      it { expect(json[:data].map { |user| user[:id] }).to include(bob.id.to_s) }
    end
  end

  describe 'POST #create' do
    context 'when passing multiple users' do
      let(:params) do
        {
          data: [
            { id: user_list[0].id, type: 'users' },
            { id: user_list[1].id, type: 'users' }
          ]
        }
      end

      before do
        post :create, group_id: group.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json[:data].map { |u| u[:id] }).to include user_list[0].id.to_s }
    end

    context 'when passing a single user' do
      let(:params) do
        {
          data: { id: user_list[0].id, type: 'users' }
        }
      end

      before do
        post :create, group_id: group.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
    end
  end

  describe 'DELETE #destroy' do
    before do
      bob.follow(group)
      mary.follow(group)
      delete :destroy, group_id: group.id, id: bob.id
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json[:data].count).to eql 2 }
  end
end
