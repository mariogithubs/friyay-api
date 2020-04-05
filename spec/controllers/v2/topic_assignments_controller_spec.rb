require 'rails_helper'

describe V2::TopicAssignmentsController do
  include ControllerHelpers::JsonHelpers

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create' do
    let(:tip) { create(:tip, user_id: user.id) }
    let(:topic) { create(:topic, title: 'Topic A') }
    let(:topic_b) { create(:topic, title: 'Topic B') }
    let(:existing_topics) { create_list(:topic, 2) }

    let(:params) do
      {
        data: {
          topic_id: topic.id
        }
      }
    end

    context 'when no assignments exist' do
      before do
        post :create, tip_id: tip.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 201 }

      it 'adds new assignment to a list' do
        expect(tip.following_topics.map(&:id)).to include topic.id
      end
    end

    context 'when one assignment exists' do
      before do
        tip.follow topic_b

        post :create, tip_id: tip.id, data: params[:data], format: :json
      end

      it 'adds new assignment to existing' do
        assignment_ids = tip.following_topics.map(&:id)
        expect(assignment_ids).to include topic.id
        expect(assignment_ids).to include topic_b.id
      end
    end
  end

  describe 'POST #move' do
    let(:tip) { create(:tip, user_id: user.id) }
    let(:topic_a) { create(:topic, title: 'Topic A') }
    let(:topic_b) { create(:topic, title: 'Topic B') }
    let(:existing_topics) { create_list(:topic, 2) }

    let(:params) do
      {
        data: {
          from_topic: topic_a.id,
          to_topic: topic_b.id
        }
      }
    end

    context 'when only one assignment exists' do
      before do
        tip.follow topic_b

        post :move, tip_id: tip.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 200 }

      it 'removes old assignment and adds new' do
        following_topics = tip.following_topics

        expect(following_topics.count).to eql 1
        expect(following_topics).to include topic_b
        expect(following_topics).to_not include topic_a
      end
    end

    context 'when several assignments exist' do
      before do
        existing_topics.each do |existing_topic|
          tip.follow existing_topic
        end

        tip.follow topic_b

        post :move, tip_id: tip.id, data: params[:data], format: :json
      end

      it 'removes old assignment an adds new to list' do
        following_topics = tip.following_topics

        expect(following_topics.count).to eql 3
        expect(following_topics).to include topic_b
        expect(following_topics).to_not include topic_a
      end
    end
  end
end
