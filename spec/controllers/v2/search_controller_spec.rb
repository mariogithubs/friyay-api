require 'rails_helper'

describe V2::SearchController do
  # include SolrSpecHelper
  # let(:user) { User.first || create(:user) }

  # before do
  #   user
  #   request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
  #   request.host = 'api.tiphive.dev'
  # end

  describe 'GET index' do
    # TEST all, then by resource, then within a Hive
    describe 'solr server required' do
      # TODO: I CAN'T GET THIS TEST TO WORK
      # THE TOPIC IS BEING CREATED, MAYBE NOT INDEXED IN THE TEMP SOLR SERVER?
      # before :all do
      #   solr_setup
      # end

      # before :each do
      #   FactoryGirl.create(:topic, title: 'Test Title')
      #   get :index, q: 'test', format: :json
      # end

      # after :all do
      #   # Assumes specs are using topic for tests, not another entity
      #   Topic.remove_all_from_index!
      # end

      # context ':q contains search terms' do
      #   it { expect(response).to have_http_status(:ok) }
      # end

      # context 'a type is specified' do
      #   it { expect(response).to have_http_status(:ok) }
      # end
    end

    describe 'solr server not required' do
      # context ':q does not contain search terms' do
      #   before do
      #     get :index, format: :json
      #   end

      #   it { expect(json[:errors]).to_not be_nil }
      # end

      # context 'no results are found' do
      #   before do
      #     get :index, type: 'User', q: 'test', format: :json
      #   end

      #   it { expect(response).to have_http_status(:ok) }
      # end
    end
  end
end
