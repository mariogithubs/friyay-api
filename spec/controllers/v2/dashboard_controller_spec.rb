require 'rails_helper'

RSpec.describe V2::DashboardController, type: :controller do
  # let(:admin) { User.first || create(:user) }
  let(:user) { create(:admin) }

  before do
    user.join(Domain.find_by(tenant_name: 'app'))

    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'index' do
    before do
      get :index, format: :json
    end

    it { expect(response.status).to eql 200 }
    it { expect(json[:data]).to_not be_nil }
    it { expect(json[:data][:stats].first.keys).to include(:domain) }
  end
end
