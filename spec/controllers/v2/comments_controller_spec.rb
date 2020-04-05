require 'rails_helper'

describe V2::CommentsController do
  let(:user) { create(:user) }

  before do
    user
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET index' do
    let(:tip) { create(:tip, user: user) }
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:comment1) { create(:comment, user: bob, commentable: tip) }
    let(:comment_list) { create_list(:comment, 3, user: user, commentable: tip) }
    let(:reply) { create(:comment, parent: comment1, commentable: comment1.commentable, user: user) }

    before do
      comment1
      comment_list
      reply
      get :index, tip_id: tip.id, format: :json
    end

    it { expect(response.status).to eql 200 }
    it { expect(json[:data]).to_not be_nil }
    it { expect(json[:data].count).to eql 5 }
    it { expect(json[:data].first[:relationships][:replies][:data].count).to be > 0 }
    it { expect(json[:data].last[:attributes][:user][:id]).to_not be_nil }
  end

  TestAfterCommit.with_commits(true) do
    Sidekiq::Testing.disable! do
      describe 'POST #create' do
        context 'when a tip comment' do
          let(:tip) { create(:tip) }

          let(:params) do
            {
              data: {
                type: 'comments',
                attributes: {
                  body: FFaker::Lorem.paragraph
                },
                relationships: {
                  commentable: {
                    data: { id: tip.id, type: 'tips' }
                  }
                }
              }
            }
          end

          context 'when successful' do
            before do
              post :create, data: params[:data], format: :json
            end

            it { expect(response.status).to eql 201 }
            it { expect(json[:data][:attributes][:body]).to_not be_nil }
            it { expect(tip.comment_threads.count).to be > 0 }
            it { expect(User.find(user.id).user_profile.settings(:counters).total_comments).to be > 0 }
          end

          context 'when create fails' do
            before do
              params[:data][:attributes][:body] = nil
              post :create, data: params[:data], format: :json
            end

            it { expect(response.status).to eql 422 }
          end

          context 'when there is a mention' do
            let(:bob) { create(:user, first_name: 'Bob', last_name: 'Mention') }
            let(:mary) { create(:user, first_name: 'Mary', last_name: 'Mention') }

            before do
              bob
              mary
              params[:data][:attributes][:body] =
                '<span>@BobMention</span>, <span>tom@test.com</span> <span>@marymention</span>'
              post :create, data: params[:data], format: :json
            end

            it { expect(Mention.count).to eql 2 }
            it { expect(Mention.all.map(&:user_id)).to include bob.id }
          end
        end
      end # describe
    end # Sidekiq
  end # TestAfterCommit

  describe 'PATCH #update' do
    context 'when a tip comment' do
      let(:tip) { create(:tip) }
      let(:comment) do
        comment = Comment.build_from(tip, user.id, 'Test Comment')
        comment.save
        comment
      end

      let(:params) do
        {
          data: {
            id: comment.id,
            type: 'comments',
            attributes: {
              body: 'Updated Test Comment'
            }
          }
        }
      end

      context 'when update successful' do
        before do
          patch :update, id: comment.id, data: params[:data], format: :json
        end

        it { expect(response.status).to eql 200 }
        it { expect(json[:data][:attributes][:body]).to eql 'Updated Test Comment' }
      end

      context 'when update fails' do
        before do
          params[:data][:attributes][:body] = nil
          post :update, id: comment.id, data: params[:data], format: :json
        end

        it { expect(response.status).to eql 422 }
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:comment) { create(:comment, user: user) }
    let(:child) { create(:comment, parent: comment, commentable: comment.commentable, user: create(:user)) }

    context 'when comment only' do
      before do
        comment
        delete :destroy, id: comment.id
      end

      it { expect(response.status).to eql 204 }
      it { expect(Comment.find_by(id: comment.id)).to be_nil }
      it { expect(User.find(user.id).user_profile.settings(:counters).total_comments).to eql 0 }
    end

    context 'when comment + child' do
      before do
        child
        delete :destroy, id: comment.id
      end

      it { expect(Comment.find_by(id: comment.id)).to be_nil }
      it { expect(Comment.find_by(id: child.id)).to be_nil }
    end
  end

  describe 'reply' do
    let(:tip) { create(:tip, user: user) }
    let(:comment) { create(:comment, user: user, commentable: tip) }
    let(:bob) { create(:user, first_name: bob) }

    let(:params) do
      {
        data: {
          type: 'comments',
          attributes: {
            body: 'This is a reply'
          }
        }
      }
    end

    before do
      post :reply, id: comment.id, data: params[:data], format: :json
    end

    context 'PERMISSIONS: commenting is ALLOWED' do
      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:body]).to eql 'This is a reply' }
      it { expect(comment.children.count).to eql 1 }
    end
  end

  # describe 'PERMISSIONS: reply' do
  #   let(:member) { create(:user) }
  #   let(:topic) { create(:topic, user: member) }

  #   let(:tip) { create(:tip, user: user) }
  #   let(:comment) { create(:comment, user: user, commentable: tip) }
  #   let(:bob) { create(:user, first_name: bob) }

  #   let(:params) do
  #     {
  #       data: {
  #         type: 'comments',
  #         attributes: {
  #           body: 'This is a reply'
  #         }
  #       }
  #     }
  #   end

  #   before do
  #     tip.follow topic

  #     topic.create_topic_permission(
  #       access_hash: ActivityPermission::DEFAULT_ACCESS_HASH.merge(comment_tip: {})
  #     )

  #     post :reply, id: comment.id, data: params[:data], format: :json
  #   end

  #   context "PERMISSIONS: commenting is NOT ALLOWED" do
  #     it { expect(response.status).to eql 401 }
  #     it { expect(comment.children.count).to eql 0 }
  #   end
  # end
end
