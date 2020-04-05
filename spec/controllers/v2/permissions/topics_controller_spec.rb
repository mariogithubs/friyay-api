require 'rails_helper'

describe V2::TopicsController do
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

  let(:hive_access_hash) { default_permission }

  before do
    user
    user.join(domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #show' do
    let(:user)  { create(:user) }

    context 'member can read topic created by any user' do
      let(:topic) { create(:topic, user: bob) }

      before :each do
        get :show, id: topic, format: :json
      end

      it { expect(response.status).to eql(200) }
    end
  end

  describe 'POST #create' do
    let(:topic) { build(:topic) }

    let(:params) do
      {
        data: {
          type: 'topics',
          attributes: {
            title: topic.title,
            description: topic.description
          },
          relationships: {
            topic_preferences: {
              data: [
                {
                  type: 'topic_preferences'
                }.merge(attributes_for(:topic_preference))
              ]
            }
          }
        }
      }
    end

    before do
      domain.update_attributes(domain_permission_attributes: {access_hash: updated_access_hash})
      domain.reload

      post :create, data: params[:data], format: :json
    end

    context 'admin can create a new topic when allowed by admin' do
      let(:user)  { admin }
      let(:updated_access_hash) { default_permission.merge({ create_topic: { :roles=>["member"] } }) }

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql(201) }
      it do
        topic = Topic.find json[:data][:id]
        expect(user.has_role? 'admin', topic)
      end
    end

    context 'admin can create a new topic even when restricted by admin' do
      let(:user)  { admin }
      let(:updated_access_hash) { default_permission.merge({ create_topic: {} }) }

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql(201) }
      it do
        topic = Topic.find json[:data][:id]
        expect(user.has_role? 'admin', topic)
      end
    end

    context 'member can create a new topic when allowed by admin' do
      let(:user) { create(:user) }

      let(:updated_access_hash) { default_permission.merge({ create_topic: { :roles=>["member"] } }) }

      before(:each) do
        user.join(domain)
      end

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql(201) }
      it do
        topic = Topic.find json[:data][:id]
        expect(user.has_role? 'admin', topic)
      end
    end

    context 'member cannot create a new topic when restricted by admin' do
      let(:user) { create(:user) }

      let(:updated_access_hash) { default_permission.merge({ create_topic: {} }) }

      before(:each) do
        user.join(domain)
      end

      it { expect(response.status).to eql 401 }
      it { expect(json[:errors]).to eql({ title: 'You are not authorized to perform that request.' }) }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:topic) { create(:topic) }

    let(:params) do
      {
        data: {
          id: topic.id,
          type: 'topics',
          attributes: {
            title: 'An updated topic title'
          },
          relationships: {
            topic_preferences: {
              data: [
                {
                  type: 'topic_preferences'
                },
                share_following: false
              ]
            }
          }
        }
      }
    end

    before do
      domain.update_attributes(domain_permission_attributes: {access_hash: updated_access_hash})
      domain.reload

      topic.update_attributes(topic_permission_attributes: {access_hash: hive_access_hash})
      topic.reload

      patch :update,
            id: topic.id,
            data: params[:data],
            format: :json
    end

    context 'admin can update any topic when allowed by admin' do
      let(:user)  { admin }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: { :roles=>["member"] } }) }

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(topic.topic_preferences.for_user(user).share_following).to eql(false) }
    end

    context 'admin can update topic even when restricted by admin' do
      let(:user)  { admin }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: {} }) }

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(topic.topic_preferences.for_user(user).share_following).to eql(false) }
    end

    context 'creater can update topic even when restricted by admin' do
      let(:user)  { topic.user }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: {} }) }

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(topic.topic_preferences.for_user(user).share_following).to eql(false) }
    end

    context 'member cannot create any one else\'s topic when restricted by admin' do
      let(:user)  { create(:user) }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: {} }) }

      it { expect(response.status).to eql 401 }
      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end

    context 'member cannot update any one else\'s topic when allowed by domain admin but not hive admin' do
      let(:user)  { create(:user) }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: { :roles=>["member"] } }) }

      it { expect(response.status).to eql 401 }
      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end

    context 'member can update any one else\'s topic when allowed by domain admin and hive admin' do
      let(:user)  { create(:user) }
      let(:updated_access_hash) { default_permission.merge({ edit_topic: { :roles=>["member"] } }) }
      let(:hive_access_hash)    { default_permission.merge({ edit_topic: { :roles=>["member"] } }) }

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(topic.topic_preferences.for_user(user).share_following).to eql(false) }
    end
  end
end
