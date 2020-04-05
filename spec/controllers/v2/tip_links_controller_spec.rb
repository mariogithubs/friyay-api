require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe V2::TipLinksController, type: :controller do
  let(:user) { create(:user) }
  let(:tip) { create(:tip) }

  before do
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.headers['X-Tenant-Name'] = ''
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #fetch' do
    context 'url is provided' do
      before do
        params = {
          tip_id: tip.id,
          data: {
            attributes: {
              url: 'http://google.com'
            }
          }
        }

        post :fetch, params, format: :json
      end

      it { expect(json[:data][:id]).to_not be_nil }
      it { expect(json[:data][:attributes][:url]).to_not be_nil }
      it { expect(json[:data][:attributes][:processed]).to eql(false) }
      it { expect(ThumbnailerWorker.jobs.last['args']).to eql([json[:data][:id].to_i]) }
    end

    context 'url is not provided' do
      before do
        params = {
          tip_id: tip.id,
          data: {
            attributes: {
              url: ''
            }
          }
        }

        post :fetch, params, format: :json
      end

      it { expect(json[:errors][:detail]).to include('Url not provided.') }
    end
  end
end
