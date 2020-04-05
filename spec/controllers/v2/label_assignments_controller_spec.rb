require 'rails_helper'

RSpec.describe V2::LabelAssignmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:label1) { create(:label, name: 'Bookmark1', user_id: user.id) }
  let(:label2) { create(:label, name: 'Bookmark2', user_id: user.id) }
  let(:tip_list) { create_list(:tip, 2, user_id: user.id) }

  before do
    # Make sure to invoke user and join them to 'app', which is the non-public domain
    # Most of our tests are scoped to a domain, only using public where there is a bug
    user.join(Domain.find_by(tenant_name: 'app'))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe '#POST create' do
    context 'when using existing labels and tips' do
      let(:params) do
        {
          data: {
            type: 'label_assignment',
            attributes: {
              label_id: label1.id,
              item_id: tip_list[0].id,
              item_type: 'Tip'
            }
          }
        }
      end

      before do
        label1
        label2
        tip_list

        post :create, data: params[:data], format: :json
      end

      # it { expect(response.body).to be_nil } # View body for errors
      it { expect(response).to have_http_status(:created) }
    end

    # context 'when trying a non-existing label' do
    #   let(:params) do
    #     {
    #       data: {
    #         type: 'label_assignment',
    #         attributes: {
    #           label_id: 5,
    #           item_id: tip_list[0].id,
    #           item_type: 'Tip'
    #         }
    #       }
    #     }
    #   end

    #   before do
    #     tip_list

    #     post :create, data: params[:data], format: :json
    #   end

    #   # it { expect(response.body).to be_nil } # View body for errors
    #   it { expect(response).to_not have_http_status(:created) }
    # end
  end
end
