require 'rails_helper'

RSpec.describe V2::LabelOrdersController, type: :controller do
	let(:user) { create(:user) }

	before do
	  # Make sure to invoke user and join them to 'app', which is the non-public domain
	  # Most of our tests are scoped to a domain, only using public where there is a bug
	  user.join(Domain.find_by(tenant_name: 'app'))
	  request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
	  request.host = 'api.tiphive.dev'
	end

	describe '#POST create' do
	  context 'when creating label' do
	    let(:params) do
	      {
	        data: {
	          type: 'label_orders',
	          attributes: {
	            name: "label order test",
            	order: [2,4,5]
	          }
	        }
	      }
	    end

	    before do
	      post :create, data: params[:data], format: :json
	    end

	    it { expect(response).to have_http_status(:created) }
	  end
	end
end
