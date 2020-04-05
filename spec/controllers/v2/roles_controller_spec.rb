# require 'rails_helper'

# RSpec.describe V2::RolesController, type: :controller do
#   # let(:user) { create(:user) }
#   # let(:domain) { create(:domain, user: user) }

#   # before do
#   #   user
#   #   request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
#   #   request.host = 'api.tiphive.dev'
#   # end

#   # describe 'POST #create' do
#   #   let(:hive) { create(:topic, user: user) }
#   #   let(:hive2) { create(:topic) }
#   #   let(:member) { create(:user) }

#   #   context 'when authorized to change roles' do
#   #     let(:params) do
#   #       {
#   #         topic_id: hive.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:created) }
#   #     it { expect(json[:data][:attributes][:roles][0][:name]).to eql('admin') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_type]).to eql('Topic') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_id]).to eql(hive.id) }
#   #   end

#   #   context 'when invalid role' do
#   #     let(:params) do
#   #       {
#   #         topic_id: hive.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'administrator'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(422) }
#   #     it { expect(json[:errors][:detail]).to eql(['Please specify valid role.']) }
#   #   end

#   #   context 'when not authorized to change role' do
#   #     let(:params) do
#   #       {
#   #         topic_id: hive2.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #create tip role' do
#   #   let(:tip) { create(:tip, user: user) }
#   #   let(:tip2) { create(:tip) }
#   #   let(:member) { create(:user) }

#   #   context 'when authorized to change roles' do
#   #     let(:params) do
#   #       {
#   #         tip_id: tip.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:created) }
#   #     it { expect(json[:data][:attributes][:roles][0][:name]).to eql('admin') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_type]).to eql('Tip') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_id]).to eql(tip.id) }
#   #   end

#   #   context 'when invalid role' do
#   #     let(:params) do
#   #       {
#   #         tip_id: tip.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'administrator'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(422) }
#   #     it { expect(json[:errors][:detail]).to eql(['Please specify valid role.']) }
#   #   end

#   #   context 'when not authorized to change role' do
#   #     let(:params) do
#   #       {
#   #         tip_id: tip2.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #create domain role' do
#   #   let(:member) { create(:user) }

#   #   before do
#   #     Apartment::Tenant.switch! domain.tenant_name
#   #   end

#   #   context 'when authorized to change roles' do
#   #     let(:params) do
#   #       {
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:created) }
#   #     it { expect(json[:data][:attributes][:roles][0][:name]).to eql('admin') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_type]).to eql('Domain') }
#   #     it { expect(json[:data][:attributes][:roles][0][:resource_id]).to eql(domain.id) }
#   #   end

#   #   context 'when invalid role' do
#   #     let(:params) do
#   #       {
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'administrator'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(422) }
#   #     it { expect(json[:errors][:detail]).to eql(['Please specify valid role.']) }
#   #   end

#   #   context 'when not authorized to change role' do
#   #     let(:params) do
#   #       {
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       Apartment::Tenant.switch! 'app'
#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #remove' do
#   #   let(:hive) { create(:topic, user: user) }
#   #   let(:member) { create(:user) }

#   #   context 'when authorized to remove roles' do
#   #     let(:params) do
#   #       {
#   #         topic_id: hive.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:ok) }
#   #     it { expect(json[:data][:attributes][:roles].count).to eql(1) }
#   #   end

#   #   context 'when not authorized to remove roles' do
#   #     let(:hive2) { create(:topic) }

#   #     let(:params) do
#   #       {
#   #         topic_id: hive2.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #remove tip role' do
#   #   let(:tip) { create(:tip, user: user) }
#   #   let(:member) { create(:user) }

#   #   context 'when authorized to remove roles' do
#   #     let(:params) do
#   #       {
#   #         tip_id: tip.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:ok) }
#   #     it { expect(json[:data][:attributes][:roles].count).to eql(1) }
#   #   end

#   #   context 'when not authorized to remove roles' do
#   #     let(:tip2) { create(:tip) }

#   #     let(:params) do
#   #       {
#   #         tip_id: tip2.id,
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #remove domain role' do
#   #   let(:member) { create(:user) }

#   #   before do
#   #     Apartment::Tenant.switch! domain.tenant_name
#   #   end

#   #   context 'when authorized to remove roles' do
#   #     let(:params) do
#   #       {
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(:ok) }
#   #     it { expect(json[:data][:attributes][:roles]).to eql([]) }
#   #   end

#   #   context 'when not authorized to remove roles' do
#   #     let(:params) do
#   #       {
#   #         data: {
#   #           user_id: member.id,
#   #           role: 'admin'
#   #         }
#   #       }
#   #     end

#   #     before do
#   #       Apartment::Tenant.switch! 'app'
#   #       post :remove, params, format: :json
#   #     end

#   #     it { expect(response).to have_http_status(401) }
#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end
# end
