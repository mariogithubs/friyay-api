require 'rails_helper'

describe V2::TipAssignmentsController, type: :controller do
  let(:user) { create(:user, first_name: 'Sally') }
  let(:group) { create(:group, title: 'group 1', user_id: user.id ) }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create' do
    let(:tip) { create(:tip) }
    let(:assigned_user) { create(:user) }

    before do
      post :create, tip_id: tip.id, user_id: user.id, group_id: group.id, format: :json
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json[:data][:type]).to eql 'tips' }
    it { expect(TipAssignment.count).to eql 2 }
  end
end
