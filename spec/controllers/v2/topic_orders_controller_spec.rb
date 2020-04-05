require 'rails_helper'

RSpec.describe V2::TopicOrdersController, type: :controller do
  let(:user) { create(:user) }
  
  before do
    user.join(Domain.find_by(tenant_name: 'app'))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end
  
  describe 'POST #create' do
    let(:topic) { create(:topic) }
    let(:params) do
      {
        data: {
          attributes: {
            name: 'Test order',
            user_id: user.id,
            topic_id: topic.id
          }
        }
      }
    end

    context 'when no orders have been created' do
      before do
        post :create, data: params[:data], format: :json
      end

      it { expect(response.status).to eql(201) }
      it { expect(TopicOrder.find(json[:data][:id]).is_default).to be true }
    end

    context 'when there are orders already' do
      let(:default_order) { create(:topic_order, topic: topic, name: 'Default order', is_default: true) }
      
      before do
        default_order
        post :create, data: params[:data], format: :json
      end

      it { expect(response.status).to eql(201) }
      it { expect(TopicOrder.find(json[:data][:id]).is_default).to be false }

      context 'when making order default' do

        before do
          data = params[:data]
          data[:attributes][:is_default] = true
          patch :update, id: json[:data][:id], data: data, format: :json
          @order = TopicOrder.find(json[:data][:id])
        end

        it { expect(@order.is_default).to be true }

      end
    end

  end
end
