require 'rails_helper'
require 'stripe_mock'

RSpec.describe V2::ContactInformationController, type: :controller, live: true do

  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { create(:user, first_name: 'Sally', last_name: "Appleseed",  email: "sally@appleseed.com") }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }
  let(:contact_information) { create(:contact_information, domain: domain) }


  let(:params) do
    {
      data: {
        attributes: {
          first_name: user.first_name,
          last_name: user.last_name,
          company_name: "Xyz co ltd",
          address: "Greeley Square",
          appartment: "park aenue",
          city: "Newyork",
          country: "USA",
          state: "newyork",
          zip: "10001"
          }
      }
    }
  end

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
    #create customer with card token 
    card_token  = stripe_helper.generate_card_token
    customer = StripeTool.create_customer(domain.name, user.email, card_token)
    domain.update_stripe_card_and_customer(card_token, customer['id'])
  end

  describe 'POST #create' do
    context 'valid attrs' do
      before do
        post :create, data: params[:data], format: :json
      end
      it { expect(response).to have_http_status(:created) }
    end
  end

  describe '#GET show' do
    before do
      contact_information = ContactInformation.new(first_name: user.first_name, last_name: user.last_name)
      contact_information.domain = domain
      contact_information.save  
      get :show, id: domain.id, format: :json
    end
    it { expect(response).to have_http_status(:success) }
    it { expect(json[:id]).to eql domain.contact_information.id }
  end

  describe '#PATCH update' do
    before do
      params[:data][:attributes][:first_name] = 'walle'
      patch :update, id: contact_information, data: params[:data], format: :json
    end
    it { expect(response).to have_http_status(:ok) }
  end

  describe '#GET countries' do
    before do
      get :countries, format: :json
    end
    it { expect(response).to have_http_status(:success) }
    it 'returns countries data count' do
      expect(json.count).to eql 248
    end
  end

  describe '#GET states' do
    before do
      get :states, :country => "us", format: :json
    end
    it { expect(response).to have_http_status(:success) }
    it 'returns states data count' do
      expect(json.count).to eql 51
    end
  end


end
