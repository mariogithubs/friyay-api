require 'rails_helper'

RSpec.describe  V2::LabelCategoriesController, type: :controller do
  let(:user) { create(:user) }
  let(:label_category) { create(:label_category, name: 'label category 1') }

  let(:bob) { User.find_by(first_name: 'Bob') || create(:user, first_name: 'Bob') }

  let(:base_params) do
    {
      data: {
        type: 'label_categories',
        attributes: attributes_for(:label_category, name: 'Red Hot')
      }
    }
  end

  before do
    # Make sure to invoke user and join them to 'app', which is the non-public domain
    # Most of our tests are scoped to a domain, only using public where there is a bug
    user.join(Domain.find_by(tenant_name: 'app'))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe '#POST create' do
    context 'when using base setup' do
      before do
        post :create, data: base_params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json[:data][:attributes][:name]).to eql 'Red Hot' }
    end
  end

  describe '#GET show' do
    before do
      get :show, id: label_category, format: :json
    end

    it { expect(response).to have_http_status(:success) }
    it { expect(json[:data]).to_not be_nil }
    it { expect(json[:data][:id]).to eql label_category.id.to_s }
  end
end
