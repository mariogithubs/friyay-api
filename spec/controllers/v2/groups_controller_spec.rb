require 'rails_helper'

describe V2::GroupsController do
  include ControllerHelpers::JsonHelpers

  let(:user) { create(:user) }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  let(:bob) { create(:user, first_name: 'Bob') }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    let(:groups) { create_list(:group, 5, user: bob) }

    before do
      groups.first(3).each do |group|
        user.follow(group)
      end
      bob.follow(groups.first)

      get :index, format: :json
    end

    it { expect(response).to have_http_status(:success) }

    it 'returns only groups user follows' do
      expect(json[:data].count).to eql 3
    end
  end

  describe 'GET #show' do
    let(:group) { create(:group) }

    context 'when owned group' do
      before do
        group.update_attribute(:user_id, user.id)
        get :show, id: group.id, format: :json
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:id]).to eql group.id.to_s }
    end

    context 'when member of group' do
      before do
        user.follow(group)
        get :show, id: group.id, format: :json
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:id]).to eql group.id.to_s }
    end
  end

  describe 'POST #create' do
    context 'when including users' do
      let(:group_attributes) { attributes_for(:group, title: 'Test Group') }
      let(:user_list) { create_list(:user, 2) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 2, user: user) }
      let(:topic_no_children) { create(:topic, user: user) }

      let(:params) do
        {
          data: {
            type: 'groups',
            attributes: group_attributes,
            relationships: {
              user_followers: {
                data: [
                  { id: user_list[0].id, type: 'users' },
                  { id: user_list[1].id, type: 'users' }
                ]
              },
              subtopics: {
                data: [
                  { id: topic_no_children.id, type: 'topics' },
                  { id: topic.children[0].id, type: 'topics' }
                ]
              }
            }
          }
        }
      end

      before do
        post :create, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json[:data][:relationships][:user_followers][:data].count).to eql 3 }

      it 'creates subtopic connections' do
        subtopic_ids_to_match = json[:data][:relationships][:subtopics][:data].map { |subtopic| subtopic[:id] }
        expect(subtopic_ids_to_match).to include(topic.children[0].id.to_s)
        expect(subtopic_ids_to_match).to_not include(topic.children[1].id.to_s)
      end

      # it 'creates root topic connections' do
      #   root_topic_ids_to_match = json[:data][:relationships][:topics][:data].map { |topic| topic[:id] }
      #   expect(root_topic_ids_to_match).to include(topic.id.to_s)
      #   expect(root_topic_ids_to_match).to include(topic_no_children.id.to_s)
      # end
    end
  end

  describe 'PATCH #update' do
    context 'when changing title' do
      let(:group) { create(:group, user: user, title: 'Group Name') }

      let(:params) do
        {
          data: {
            id: group.id,
            type: 'groups',
            attributes: {
              title: 'Updated Group Name'
            }
          }
        }
      end

      before do
        patch :update, id: group.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data][:attributes][:title]).to eql 'Updated Group Name' }
    end

    context 'when updating users' do
      let(:group) { create(:group, user: user, title: 'Group Name') }
      let(:bob) { create(:user, first_name: 'Bob') }
      let(:mary) { create(:user, first_name: 'Mary') }

      let(:params) do
        {
          data: {
            id: group.id,
            type: 'groups',
            attributes: { title: 'Updated Group Name' },
            relationships: {
              user_followers: {
                data: [{ id: mary.id, type: 'users' }]
              }
            }
          }
        }
      end

      before do
        bob.follow(group)

        patch :update, id: group.id, data: params[:data], format: :json
      end

      it { expect(json[:data][:relationships][:user_followers][:data].count).to eql 2 }
    end

    context 'when updating topics' do
      let(:group) { create(:group, user: user, title: 'Group Name') }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 2, user: user) }

      let(:params) do
        {
          data: {
            id: group.id,
            type: 'groups',
            attributes: { title: 'Updated Group Name' },
            relationships: {
              subtopics: {
                data: [{ id: topic.children[1].id, type: 'topics' }]
              }
            }
          }
        }
      end

      before do
        group.follow(topic.children[0])

        patch :update, id: group.id, data: params[:data], format: :json
      end

      it { expect(json[:data][:relationships][:subtopics][:data][0][:id]).to eql topic.children[1].id.to_s }
    end
  end

  describe '#DELETE #destroy' do
    context 'when owned by user' do
      let(:group) { create(:group, user: user) }

      before do
        delete :destroy, id: group.id, format: :json
      end

      it { expect(response.status).to eql 204 }
      it { expect(Group.find_by(id: group.id)).to be_nil }
    end

    context 'when authorized as admin' do
      let(:group) { create(:group) }

      before do
        user.add_role :admin, domain
        delete :destroy, id: group.id, format: :json
      end

      it { expect(Group.find_by(id: group.id)).to be_nil }
    end
  end

  # TODO: MOVE THIS TEST TO GroupMembershipController
  # describe 'POST #join' do
  #   let(:group) { create(:group) }

  #   before do
  #     post :join, id: group.id, data: {}, format: :json
  #   end

  #   it { expect(response).to have_http_status(:ok) }
  #   it { expect(json[:data][:id]).to eql group.id.to_s }

  #   context 'invite only group' do
  #     let(:group2) { create(:group, join_type: :invite) }

  #     before do
  #       post :join, id: group2.id, data: {}, format: :join
  #     end

  #     it { expect(json[:errors]).to_not be_nil }
  #     it { expect(response).to have_http_status(:unprocessable_entity) }
  #   end
  # end

  # describe 'POST #request_invitation' do
  #   let(:group) { create(:group, join_type: :invite) }

  #   before do
  #     post :request_invitation, id: group.id, data: {}, format: :join
  #   end

  #   it { expect(json[:data][:type]).to eql 'invitations' }
  #   it { expect(json[:data][:relationships][:invitable][:data][:type]).to eql 'groups' }
  #   it { expect(json[:data][:relationships][:invitable][:data][:id]).to eql group.id.to_s }
  # end

  # COMMENTED November 29, 2016 UNTIL WE NEED TO TEST UPLOADS AGAIN
  # TestAfterCommit.with_commits(true) do
  #   Sidekiq::Testing.fake! do
  #     describe 'POST #create' do
  #       let(:group_attributes) { attributes_for(:group, title: 'Test Group') }

  #       let(:params) do
  #         {
  #           data: {
  #             type: 'groups',
  #             attributes: group_attributes
  #           }
  #         }
  #       end

  #       before do
  #         # ::CarrierWave::Workers::StoreAsset.jobs.clear
  #         # ::CarrierWave::Workers::ProcessAsset.jobs.clear
  #         post :create, data: params[:data], format: :json
  #       end

  #       it { expect(response).to have_http_status(:created) }
  #       it { expect(json[:errors]).to be_nil }
  #       it { expect(json[:data][:attributes][:title]).to eql 'Test Group' }
  #       # it do
  #       #   expect(json[:data][:attributes][:avatar_processing]).to eql(true)
  #       #   expect(json[:data][:attributes][:background_image_processing]).to eql(true)
  #       #   expect(::CarrierWave::Workers::StoreAsset.jobs.size).to eql(2)
  #       #   ::CarrierWave::Workers::StoreAsset.drain
  #       #   group = Group.find json[:data][:id]
  #       #   expect(group.avatar_processing).to eql(false)
  #       #   expect(group.background_image_processing).to eql(false)
  #       # end
  #     end

  #     describe 'POST #create_for_http_uploads' do
  #       let(:group_attributes) { attributes_for(:group_with_http_upload, title: 'Test Group HTTP upload') }

  #       let(:params) do
  #         {
  #           data: {
  #             type: 'groups',
  #             attributes: group_attributes
  #           }
  #         }
  #       end

  #       before do
  #         # ::CarrierWave::Workers::StoreAsset.jobs.clear
  #         # ::CarrierWave::Workers::ProcessAsset.jobs.clear
  #         post :create, data: params[:data], format: :json
  #       end

  #       it { expect(response).to have_http_status(:created) }
  #       it { expect(json[:errors]).to be_nil }
  #       it { expect(json[:data][:attributes][:title]).to eql 'Test Group HTTP upload' }
  #       # it do
  #       #   expect(json[:data][:attributes][:avatar_processing]).to eql(true)
  #       #   expect(::CarrierWave::Workers::StoreAsset.jobs.size).to eql(1)
  #       #   ::CarrierWave::Workers::StoreAsset.drain
  #       #   group = Group.find json[:data][:id]
  #       #   expect(group.avatar_processing).to eql(false)
  #       # end
  #     end
  #   end
  # end

  # TODO: create tests for groups of join_type: domain and location
end
