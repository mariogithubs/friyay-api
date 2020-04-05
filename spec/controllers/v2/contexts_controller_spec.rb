require 'rails_helper'

RSpec.describe V2::ContextsController, type: :controller do
  include ControllerHelpers::ContextHelpers

  let(:user) { User.first || create(:user) }

  before do
    user.join(Domain.find_by(tenant_name: 'app'))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    let(:contexts) { create_list(:context, 3) }

    context 'when topic_id not specified' do
      before do
        contexts

        get :index, format: :json
      end

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it { expect(json[:data].count).to eql Context.all.count }
    end

    context 'when topic_id specified' do
      let(:topic) { create(:topic, user: user) }
      let(:topic_2) { create(:topic, user: user) }
      let(:bob) { create(:user, first_name: 'Bob') }

      let(:user_topic_context) do
        create(:context,
               topic_id: topic.id,
               context_uniq_id: "user:#{user.id}:domain:1:topic:#{topic.id}"
              )
      end

      let(:bob_topic_context) do
        create(:context,
               topic_id: topic.id,
               context_uniq_id: "user:#{bob.id}:domain:1:topic:#{topic.id}"
              )
      end

      let(:topic_2_context) do
        create(:context,
               topic_id: topic_2.id,
               context_uniq_id: "user:#{user.id}:domain:1:topic:#{topic_2.id}"
              )
      end

      before do
        user_topic_context
        bob_topic_context
        topic_2_context

        get :index, topic_id: topic.id, format: :json
      end

      it { expect(json[:data].count).to eql topic.contexts.count }
    end
  end

  describe 'GET #create' do
    let(:topic) { create(:topic, user: user) }
    before do
      topic

      post :create, topic_id: topic.id, format: :json
    end

    it 'returns http success' do
      get :create
      expect(response).to have_http_status(:success)
    end

    it 'returns correct context' do
      context_id = Context.generate_id(
        user: user.id,
        domain: current_domain.id,
        topic: topic.id
      )
      expect(json[:data][:id]).to eql context_id
    end
  end

  # describe 'GET #destroy' do
  #   it 'returns http success' do
  #     get :destroy
  #     expect(response).to have_http_status(:success)
  #   end
  # end
end
