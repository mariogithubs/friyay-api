# require 'rails_helper'
# require 'sidekiq/testing'

# RSpec.describe V2::ActivityPermissionsController, type: :controller do
#   # let(:user) { create(:user) }
#   # let(:domain) { create(:domain, user: user) }

#   # before do
#   #   request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
#   #   request.headers['X-Tenant-Name'] = ''
#   #   request.host = 'api.tiphive.dev'
#   # end

#   # describe 'POST #create' do
#   #   context 'create/update activity permissions' do
#   #     before do
#   #       Apartment::Tenant.switch! domain.tenant_name
#   #       params = {
#   #         data: {
#   #           attributes: {
#   #             activity_permissions_attributes: [
#   #               {
#   #                 action: 'answer',
#   #                 subject_class: 'Question',
#   #                 subject_role: { resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Tip',
#   #                 subject_role: { roles: ['admin'], resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Question',
#   #                 subject_role: { roles: ['admin'] }
#   #               }
#   #             ]
#   #           }
#   #         }
#   #       }

#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(json[:data][:type]).to eql('domains') }
#   #     it { expect(json[:data][:attributes][:activity_permissions]).to_not be_nil }
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Question-answer' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(resource: :owner) }
#   #     end
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Tip-update' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(roles: ['admin'], resource: :owner) }
#   #     end
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Question-update' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(roles: ['admin']) }
#   #     end
#   #   end

#   #   context 'unable to create/update activity permissions for domain when unauthorized' do
#   #     before do
#   #       Apartment::Tenant.switch! 'app'
#   #       params = {
#   #         data: {
#   #           attributes: {
#   #             activity_permissions_attributes: [
#   #               {
#   #                 action: 'answer',
#   #                 subject_class: 'Question',
#   #                 subject_role: { resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Tip',
#   #                 subject_role: { roles: ['admin'], resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Question',
#   #                 subject_role: { roles: ['admin'] }
#   #               }
#   #             ]
#   #           }
#   #         }
#   #       }

#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end

#   # describe 'POST #create' do
#   #   context 'create/update activity permissions for hive' do
#   #     let(:hive) { create(:topic, user: user) }

#   #     before do
#   #       Apartment::Tenant.switch! 'app'
#   #       params = {
#   #         topic_id: hive.id,
#   #         data: {
#   #           attributes: {
#   #             activity_permissions_attributes: [
#   #               {
#   #                 action: 'answer',
#   #                 subject_class: 'Question',
#   #                 subject_role: { resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Tip',
#   #                 subject_role: { roles: ['admin'], resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Question',
#   #                 subject_role: { roles: ['admin'] }
#   #               }
#   #             ]
#   #           }
#   #         }
#   #       }

#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(json[:data][:type]).to eql('topics') }
#   #     it { expect(json[:data][:attributes][:activity_permissions]).to_not be_nil }
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Question-answer' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(resource: :owner) }
#   #     end
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Tip-update' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(roles: ['admin'], resource: :owner) }
#   #     end
#   #     it do
#   #       data = json[:data][:attributes][:activity_permissions].select { |k| k[:name] == 'Question-update' }
#   #       it { expect(data).to_not be_nil }
#   #       it { expect(data[0].subject_role).to eql(roles: ['admin']) }
#   #     end
#   #   end

#   #   context 'unable to create/update activity permissions for hive when unauthorized' do
#   #     let(:hive) { create(:topic) }

#   #     before do
#   #       Apartment::Tenant.switch! 'app'
#   #       params = {
#   #         topic_id: hive.id,
#   #         data: {
#   #           attributes: {
#   #             activity_permissions_attributes: [
#   #               {
#   #                 action: 'answer',
#   #                 subject_class: 'Question',
#   #                 subject_role: { resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Tip',
#   #                 subject_role: { roles: ['admin'], resource: :owner }
#   #               },
#   #               {
#   #                 action: 'update',
#   #                 subject_class: 'Question',
#   #                 subject_role: { roles: ['admin'] }
#   #               }
#   #             ]
#   #           }
#   #         }
#   #       }

#   #       post :create, params, format: :json
#   #     end

#   #     it { expect(json[:errors]).to eql(['You are not authorized to perform that request.']) }
#   #   end
#   # end
# end
