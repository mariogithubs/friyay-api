require 'rails_helper'

RSpec.describe V2::ViewAssignmentsController, type: :controller do

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create with valid attributes' do
    let(:view) { create(:view) }
    let(:allocated_user) { create(:user) }

    before do
      post :create, view_id: view.id, user_id: user.id, domain_id: domain.id, format: :json
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json[:data][:type]).to eql 'views' }
    it { expect(user.assigned_views.size).to be > 0 }
    it { expect(User.find(user.id).user_profile.settings(:counters).total_views).to be > 0 }
  end

  describe 'POST #create with invalid attributes' do
    let(:view) { create(:view) }
    let(:allocated_user) { create(:user) }

    before do
      post :create, view_id: view.id, user_id: user.id, domain_id: domain.id, format: :json
      post :create, view_id: view.id, user_id: user.id, domain_id: domain.id, format: :json
    end

    it {expect(json[:errors][:detail]).to include('View has already been taken')}
    it { expect(response.status).to eql 422 }
end

  
end
