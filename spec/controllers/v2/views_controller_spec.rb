require 'rails_helper'

RSpec.describe V2::ViewsController, type: :controller do

  let(:user) { create(:user, first_name: 'Sally') }

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  # describe 'POST #create' do
  #   it 'creates a view and increments the counter' do

  #     let(:view) { create(:view, user: user, kind: "user", name: "grid") }
  #     expect(user.user_profile.settings(:counters).total_views).to be > 0
  #   end
  # end
end
