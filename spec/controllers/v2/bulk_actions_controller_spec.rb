require 'rails_helper'

RSpec.describe V2::BulkActionsController, type: :controller do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  # include ControllerHelpers::ContextHelpers

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #archive' do
    let(:tip_list) { create_list(:tip, 5, user: user) }
    let(:john) { create(:user) }
    let(:tip_list2) { create_list(:tip, 2, user: john) }

    it 'archive all permitted tips' do
      tip_ids = (tip_list + tip_list2).map(&:id)

      post :archive, tip_ids: tip_ids, format: :json

      expect(json[:tips][:archived_tips].count).to eql 5
      expect(json[:tips][:unarchived_tips].count).to eql 2
    end
  end

  describe 'POST #organize' do
    let(:tip_list) { create_list(:tip, 3, user: user) }
    let(:topic_list) { create_list(:topic, 3) }

    it 'follow all selected topics' do
      tip_ids = tip_list.map(&:id)
      topic_ids = topic_list.map(&:id)

      post :organize, tip_ids: tip_ids, topic_ids: topic_ids, format: :json

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #share' do
    let(:tip_list) { create_list(:tip, 3, user: user) }
    let(:user_list) { create_list(:user, 3) }

    it 'share multiple selected tips with multiple users' do
      tip_ids = tip_list.map(&:id)
      user_ids = user_list.map(&:id)

      post :share, tip_ids: tip_ids, user_ids: user_ids, format: :json
    end
  end
end
