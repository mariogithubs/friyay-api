require 'rails_helper'

RSpec.describe V2::LabelsController, type: :controller do
  let(:user) { create(:user) }
  let(:label1) { create(:label, name: 'Bookmark1', user_id: user.id) }
  let(:label2) { create(:label, name: 'Bookmark2', user_id: user.id) }
  #let(:label_list) { create_list(:label, 2, user_id: user.id) }

  # Add a couple of users to be able to test with users
  let(:bob) { User.find_by(first_name: 'Bob') || create(:user, first_name: 'Bob') }
  let(:mary) { User.find_by(first_name: 'Mary') || create(:user, first_name: 'Mary') }

  let(:base_params) do
    {
      data: {
        type: 'labels',
        attributes: attributes_for(:label, name: 'Red Hot')
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

  describe '#GET index as default user' do
    context 'when no filter' do
      before do
        label1
        label2
        get :index, format: :json
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data]).to_not be_nil }

      it { expect(json[:data].count).to eql Label.count }
    end

    context 'when public filter' do
      let(:public_label) { create(:label, user_id: user.id, kind: 'public') }

      before do
        public_label
        get :index, filter: { kind: 'public' }, format: :json
      end

      # Occasionally, I'll do this just to see what I'm getting back, to help me navigate the json
      # it { expect(json[:data][0][:attributes]).to be_nil }
      it { expect(json[:data].count { |a| a[:attributes][:kind] == 'public' }).to be > 0 }
    end

    context 'when bob has a private label' do
      # We want to make sure that private labels remain private
      let(:bob_label) { create(:label, user_id: bob.id) }

      before do
        label1
        label2
        bob
        bob_label
        get :index, format: :json
      end

      # Make sure labels from all users are counted
      # expect user_labels: 3, system labels: 1 = 4 labels
      it { expect(Label.count).to eql 4 }

      it 'do not show bobs label' do
        expect(json[:data].count).to eql 3
      end
    end
  end

  describe '#POST create' do
    context 'when using base setup' do
      before do
        post :create, data: base_params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json[:data][:attributes][:name]).to eql 'Red Hot' }
    end

    context 'when creating a private label' do
    end

    context 'when creating a public label' do
    end
  end

  describe '#GET show' do
    before do
      get :show, id: label1, format: :json
    end

    it { expect(response).to have_http_status(:success) }
    it { expect(json[:data]).to_not be_nil }
    it { expect(json[:data][:id]).to eql label1.id.to_s }
  end

  describe '#PATCH update' do
    before do
      base_params[:data][:attributes][:name] = 'Read Later'
      patch :update, id: label1, data: base_params[:data], format: :json
    end

    it { expect(response).to have_http_status(:ok) }
  end

  describe '#DELETE destroy' do
    before do
      delete :destroy, id: label1, format: :json
    end

    it { expect(response).to have_http_status(:success) }
  end
end
