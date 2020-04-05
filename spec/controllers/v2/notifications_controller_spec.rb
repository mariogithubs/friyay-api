require 'rails_helper'

describe V2::NotificationsController do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers

  let(:user) { create(:user) }
  let(:bob) { create(:user, first_name: 'Bob') }
  let(:mary) { create(:user, first_name: 'Mary') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'

    user.follow bob
    user.follow mary

    # Create topic, notifications count should be increased by 1
    # because in Topic observer, it will immediately fire ActivityNotification corresponding method
    # TODO, need to fix sharing action - it doesn't work
    create(:topic, user: bob)
  end

  describe 'get list of notifications' do
    context 'when there is no filter' do
      before do
        get :index, format: :json
      end

      it { expect(response).to have_http_status(:success) }

      it 'returns the correct amount' do
        expect(json[:data].count).to eql(1)
      end
    end
  end

  # BUG: THE FOLLOWING ISN'T WORKING
  xdescribe 'mark all notifications as read' do
    before do
      patch :mark_as_read, format: :json
    end

    it 'has no unread items left' do
      expect(user.notifications.count).to eql(0)
    end
  end
end
