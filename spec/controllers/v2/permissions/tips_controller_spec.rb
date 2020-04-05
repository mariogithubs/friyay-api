require 'rails_helper'

describe V2::TipsController do
  let(:default_permission) do
    {
      :create_topic=>{:roles=>["member"]},
      :edit_topic=>{},
      :destroy_topic=>{},
      :create_tip=>{:roles=>["member"]},
      :edit_tip=>{},
      :destroy_tip=>{},
      :like_tip=>{:roles=>["member"]},
      :comment_tip=>{:roles=>["member"]},
      :create_question=>{:roles=>["member"]},
      :edit_question=>{},
      :destroy_question=>{},
      :like_question=>{:roles=>["member"]},
      :answer_question=>{:roles=>["member"]}
    }
  end

  let(:admin)  { User.first }

  let(:bob)    { User.find_by(first_name: 'Bob') || create(:user, first_name: 'Bob') }
  let(:mary)   { User.find_by(first_name: 'Mary') || create(:user, first_name: 'Mary') }
  let(:sally)  { User.find_by(first_name: 'Sally') || create(:user, first_name: 'Sally') }

  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  let(:topic)      { create(:topic, user: bob) }
  let(:hive_admin) { bob }

  let(:hive_access_hash) { default_permission }

  before do
    user
    user.join(domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #show' do
    let(:user) { create(:user) }

    let(:tip) { create(:tip, user: sally) }

    context 'member can read tip created by any user' do
      before :each do
        get :show, id: tip, format: :json
      end

      it { expect(response.status).to eql(200) }
    end

    context 'admin can read tip created by any user' do
      let(:user) { admin }

      before :each do
        get :show, id: tip, format: :json
      end

      it { expect(response.status).to eql(200) }
    end

    context 'hive admin can read tip created by any user' do
      let(:user) { hive_admin }

      before :each do
        get :show, id: tip, format: :json
      end

      it { expect(response.status).to eql(200) }
    end
  end

  # describe 'POST #create' do
  #   let(:tip) { build(:tip) }

  #   let(:params) do
  #     {
  #       data: {
  #         type: 'topics',
  #         attributes: {
  #           title: topic.title,
  #           description: topic.description
  #         },
  #         relationships: {
  #           topic_preferences: {
  #             data: [
  #               {
  #                 type: 'topic_preferences'
  #               }.merge(attributes_for(:topic_preference))
  #             ]
  #           }
  #         }
  #       }
  #     }
  #   end

  #   before do
  #     domain.update_attributes(domain_permission_attributes: {access_hash: updated_access_hash})
  #     domain.reload

  #     post :create, data: params[:data], format: :json
  #   end

  #   context 'admin can create a new topic when allowed by admin' do
  #     let(:user)  { admin }
  #     let(:updated_access_hash) { default_permission.merge({ create_topic: { :roles=>["member"] } }) }

  #     it { expect(json[:errors]).to be_nil }
  #     it { expect(response.status).to eql(201) }
  #     it do
  #       topic = Topic.find json[:data][:id]
  #       expect(user.has_role? 'admin', topic)
  #     end
  #   end
  # end
end
