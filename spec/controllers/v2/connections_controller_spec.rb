require 'rails_helper'

describe V2::ConnectionsController do
  let(:user) { create(:user) }

  before do
    user.join(current_domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe '#POST create - create a connection' do
    let(:topic) { create(:topic) }

    let(:params) do
      {
        data: {
          type: 'follows',
          attributes: {
            next: {
              follower: { id: user.id, type: 'User' },
              followable: { id: topic.id, type: 'Topic' }
            }
          }
        }
      }
    end

    context 'when user following topic' do
      before do
        post :create, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json[:data][:type]).to eql 'follows' }
      it { expect(json[:data][:relationships][:followable][:data][:id]).to eql topic.id.to_s }
    end

    context 'when tip following tip' do
      let(:parent_tip) { create(:tip, title: 'Parent', user_id: user.id) }
      let(:tip) { create(:tip, title: 'Child', user_id: user.id) }
      let(:reorder_tip) { create(:tip, title: 'This will be ordered', user_id: user.id) }
      let(:bob) { create(:user, first_name: 'Bob') }

      before do
        parent_tip.share_settings.create(
          user_id: user.id,
          sharing_object_type: 'User',
          sharing_object_id: bob.id
        )

        bob.follow(parent_tip)

        params[:data][:attributes] = {
          next: {
            follower: { id: tip.id, type: 'Tip' },
            followable: { id: parent_tip.id, type: 'Tip' }
          }
        }
      end

      context 'when moving tip from a topic' do
        before do
          tip.follow(topic)

          params[:data][:attributes][:previous] = {
            follower: { id: tip.id, type: 'Tip' },
            followable: { id: topic.id, type: 'Topic' }
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:created) }
        it { expect(tip.following?(topic)).to be false }
      end

      context 'when authorized' do
        before do
          post :create, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:created) }
        it { expect(parent_tip.tip_followers).to include(tip) }
        it { expect(parent_tip.share_settings.count).to be > 0 }

        it 'duplicates user followers' do
          tip_user_followers = tip.user_followers.pluck(:id)
          parent_user_followers = parent_tip.user_followers.pluck(:id)

          expect(tip_user_followers).to eql parent_user_followers
        end

        it 'duplicates share settings' do
          tip_share_settings = tip
                               .share_settings
                               .where(sharing_object_type: 'User')
                               .pluck(:sharing_object_id)

          parent_share_settings = parent_tip
                                  .share_settings
                                  .where(sharing_object_type: 'User')
                                  .pluck(:sharing_object_id)

          expect(tip_share_settings).to eql parent_share_settings
        end
      end

      context 'when not authorized' do
        before do
          bob.join(current_domain)

          parent_tip.update_attribute(:user_id, bob.id)
          tip.update_attribute(:user_id, bob.id)
          user.remove_role(:admin, tip)
          user.leave(current_domain)

          post :create, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'when trying to reorder as well' do
        let(:topic) { create(:topic, user: user) }

        before do
          tip.follow(parent_tip)
          tip.follow(topic)
          reorder_tip.follow(topic)

          params[:data][:attributes] = {
            next: {
              follower: { id: reorder_tip.id, type: 'Tip' },
              followable: { id: parent_tip.id, type: 'Tip' }
            }
          }

          params[:data][:reorder] = {
            topic_id: topic.id,
            preceding_tips: [tip.id]
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:created) }
        it { expect(parent_tip.tip_followers).to include(tip) }
        it { expect(ContextTip.all.count).to eql 2 }
      end
    end
  end

  describe '#POST remove_connection' do
    # USE POST BECAUSE WE HAVE TO LOOKUP THE CONNECTION IN ORDER TO DELETE
    let(:topic) { create(:topic) }

    let(:params) do
      {
        data: {
          type: 'follows',
          attributes: {
            previous: {
              follower: { id: user.id, type: 'User' },
              followable: { id: topic.id, type: 'Topic' }
            }
          }
        }
      }
    end

    context 'when tip stop following tip' do
      let(:parent_tip) { create(:tip, title: 'Parent', user_id: user.id) }
      let(:tip) { create(:tip, title: 'Child', user_id: user.id) }

      before do
        tip.follow(parent_tip)

        params[:data][:attributes] = {
          previous: {
            follower: { id: tip.id, type: 'Tip' },
            followable: { id: parent_tip.id, type: 'Tip' }
          }
        }

        delete :destroy, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(204) }
      it { expect(tip.following?(parent_tip)).to be false }
    end
  end

  describe '#PATCH update_connection' do
    let(:topic) { create(:topic) }
    let(:prev_parent) { create(:tip, user: user) }
    let(:next_parent) { create(:tip, user: user) }
    let(:tip) { create(:tip, user: user) }

    let(:params) do
      {
        data: {
          type: 'follows',
          attributes: {
            previous: {
              follower: { id: tip.id, type: 'Tip' },
              followable: { id: prev_parent.id, type: 'Tip' }
            },
            next: {
              follower: { id: tip.id, type: 'Tip' },
              followable: { id: next_parent.id, type: 'Tip' }
            }
          }
        }
      }
    end

    before do
      prev_parent.follow(topic)
      next_parent.follow(topic)
      tip.follow(prev_parent)

      post :update, data: params[:data], format: :json
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(Follow.find_by(follower_id: tip.id, followable_id: prev_parent.id)).to be_nil }
    it { expect(Follow.find_by(follower_id: tip.id, followable_id: next_parent.id)).to_not be_nil }
  end
end
