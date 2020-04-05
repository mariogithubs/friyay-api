require 'rails_helper'
require 'stripe_mock'

RSpec.describe V2::CardsController, type: :controller, live: true do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  include ControllerHelpers::ContextHelpers

  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { create(:user, first_name: 'Sally', email: "sally@appleseed.com") }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    user.add_role(:admin, domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create with valid attributes' do
    let(:params) do
      {
        data: {
          attributes: {
            stripe_card_token: stripe_helper.generate_card_token,
          }
        }
      }
    end
    context 'valid stripe card token' do
      before do
        post :create, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'POST #create with invalid attributes' do
    let(:params) do
      {
        data: {
          attributes: {
            stripe_card_token: nil,
          }
        }
      }
    end
    context 'card create with invalid attributes' do
      before do
        post :create, data: params[:data], format: :json
      end
      it { expect(json[:errors][:detail]).to include('card token is blank') }
      it { expect(response.status).to eql 422 }
    end
  end

  describe 'PUT #update with valid attributes' do
    let(:params) do
      {
        data: {
          attributes: {
            stripe_card_token: stripe_helper.generate_card_token,
          }
        }
      }
    end
    context 'valid stripe card token' do
      before do
        customer = StripeTool.create_customer(domain.name, user.email, stripe_helper.generate_card_token)
        domain.update_stripe_card_and_customer(stripe_helper.generate_card_token, customer['id'])
        put :update, id: domain.stripe_customer_id, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'PUT #update with invalid attributes' do
    let(:params) do
      {
        data: {
          attributes: {
            stripe_card_token: nil,
          }
        }
      }
    end
    context 'card create with invalid attributes' do
      before do
        customer = StripeTool.create_customer(domain.name, user.email, stripe_helper.generate_card_token)
        domain.update_stripe_card_and_customer(stripe_helper.generate_card_token, customer['id'])
        put :update, id: domain.stripe_customer_id, data: params[:data], format: :json
      end
      it { expect(json[:errors][:detail]).to include('card token is blank') }
      it { expect(response.status).to eql 422 }
    end
  end
  
end