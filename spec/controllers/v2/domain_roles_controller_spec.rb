require 'rails_helper'

describe V2::DomainRolesController do
  let(:user) { create(:user) }

  before do
    user
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    before do
      get :index, format: :json
    end

    puts "~~~~~~~~~~~~#{Role::DOMAIN_TYPES}"

    it { expect(json[:data]).to eql(Role::DOMAIN_TYPES) }
  end

  describe 'PATCH #update' do
    let(:params) do
      {
        data: {
          user_id: user.id
        }
      }
    end

    context 'when changing from admin to member' do
      let(:domain_role) { user.add_role(:admin, current_domain) }

      before do
        params[:data][:role] = 'member'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'returns http ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'makes current role == member' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'member'
      end
    end

    context 'when changing from admin to power' do
      let(:domain_role) { user.add_role(:admin, current_domain) }

      before do
        params[:data][:role] = 'power'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'returns http ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'makes current role == power' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'power'
      end
    end

    context 'when changing from member to admin' do
      before do
        user.join(current_domain, as: 'member')
        params[:data][:role] = 'admin'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'adds admin role' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'admin'
      end

      it 'keeps membership as member' do
        expect(user.member_of?(current_domain)).to be true
      end
    end

    context 'when changing from power to admin' do
      before do
        user.join(current_domain, as: 'power')
        params[:data][:role] = 'admin'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'adds admin role' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'admin'
      end

      it 'keeps membership as power' do
        expect(user.power_of?(current_domain)).to be true
      end
    end

    context 'when changing from member to guest' do
      before do
        user.join(current_domain, as: 'member')
        params[:data][:role] = 'guest'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'adds admin role' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'guest'
      end

      it 'changes membership to guest' do
        expect(user.guest_of?(current_domain)).to be true
      end

      it { expect(json[:data][:attributes][:current_domain_role]).to eql 'guest' }
    end

    context 'when changing from power to guest' do
      before do
        user.join(current_domain, as: 'power')
        params[:data][:role] = 'guest'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'adds admin role' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'guest'
      end

      it 'changes membership to guest' do
        expect(user.guest_of?(current_domain)).to be true
      end

      it { expect(json[:data][:attributes][:current_domain_role]).to eql 'guest' }
    end

    context 'when changing from guest to member' do
      before do
        user.join(current_domain, as: 'guest')
        params[:data][:role] = 'member'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'makes current role == member' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'member'
      end

      it 'changes membership to guest' do
        expect(user.member_of?(current_domain)).to be true
      end
    end

    context 'when changing from guest to power' do
      before do
        user.join(current_domain, as: 'guest')
        params[:data][:role] = 'power'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'makes current role == power' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'power'
      end

      it 'changes membership to guest' do
        expect(user.power_of?(current_domain)).to be true
      end
    end

    context 'when changing from power to member' do
      before do
        user.join(current_domain, as: 'power')
        params[:data][:role] = 'member'
        patch :update, user_id: user.id, data: params[:data], format: :json
      end

      it 'adds member role' do
        role = user.roles.current_for_domain(current_domain.id)
        expect(role.name).to eql 'member'
      end

      it 'changes membership to member' do
        expect(user.member_of?(current_domain)).to be true
      end

      it { expect(json[:data][:attributes][:current_domain_role]).to eql 'member' }
    end
    


  end
end
