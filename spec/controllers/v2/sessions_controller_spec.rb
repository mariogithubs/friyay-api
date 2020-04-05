require 'rails_helper'

describe V2::SessionsController do
  let(:user) { create(:user, email: 'myemail@gmail.com') }

  before do
    request.host = 'api.tiphive.dev'
  end

  context 'when user not found' do
    # Rely on devise, no need to test
  end

  context 'when invalid password' do
    # Rely on devise, no need to test
  end

  describe 'Special cases' do
    let(:params) do
      {
        user: {
          email: user.email,
          password: '12345678'
        }
      }
    end

    context 'when not a member of domain' do
      before do
        post :create, user: params[:user], format: :json
      end

      it { expect(json[:errors]).to_not be_nil }
    end

    context 'when a deactivated member of a domain' do
      before do
        user.join(current_domain)
        memberships = DomainMembership.where(domain: current_domain, user: user)
        memberships.each(&:deactivate!)

        post :create, user: params[:user], format: :json
      end

      it { expect(response.status).to eql 422 }
    end
  end
end
