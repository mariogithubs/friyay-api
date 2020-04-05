require 'rails_helper'

describe V2::SlackController do

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end
  context 'slack integration' do



    describe 'POST #auth' do
      
      before{
        stub_request(:post, "https://slack.com/api/oauth.access").to_return(body: File.read('spec/fixtures/slack_auth_response.json'))
        stub_request(:post, "https://slack.com/api/users.info").to_return(body: File.read('spec/fixtures/slack_user_info.json'))
        stub_request(:post, "https://slack.com/api/users.list").to_return(body: File.read('spec/fixtures/slack_user_list.json'))
      }

      let(:params) do
        {
          code: "433226453984.451398259398.98d3588df1a6bd2787705896661a46dbb49c246744477912dcb2ce34eeae1e24",
          redirectUri: "http://tiphive.test:5000/slack/auth"
        }
      end

      before do
        current_domain.update_attribute(:user_id, user.id)

        post :auth, params, format: :json
      end
      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:message]).to eql("Slack Team successfully added") }
    end


    describe 'POST #login' do

      before{
        stub_request(:post, "https://slack.com/api/oauth.access").to_return(body: File.read('spec/fixtures/slack_login.json'))
        stub_request(:post, "https://slack.com/api/users.info").to_return(body: File.read('spec/fixtures/slack_user_info.json'))
      }

      let(:params) do
        {
          code: "433226453984.451398259398.98d3588df1a6bd2787705896661a46dbb49c246744477912dcb2ce34eeae1e24",
          redirectUri: "http://tiphive.test:5000/slack/auth"
        }
      end

      context 'with slack member' do

        let!(:slack_team) { create(:slack_team, user_ids: [user.id]) }
        let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }

        before do
          post :login, format: :json
        end

        it { expect(response).to have_http_status(:created) }
        it { expect(json[:data][:attributes][:email]).to eq(user.email) }
      end

      context 'when slack member is not present' do

        before do
          post :login, format: :json
        end

        it { expect(json[:errors]).to eq("Slack Team not integrated with Hive") }

      end
    end

    describe 'POST #get_slack_data' do
      
      context 'when teamId is present in params' do
        let!(:topic) { create(:topic, user_id: user.id) }
        let!(:slack_channel) { create(:slack_channel, slack_team_id: slack_team.id) }
        let(:slack_team) { create(:slack_team, domain_id: domain.id, user_ids: [user.id], bot: {:bot_user_id=>"UCR6NDCKS", :bot_access_token=>"xoxb-433226453984-435011197223-YIOhgxW6P1nusvH99de3u2LU"}) }
        let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
        let!(:slack_topic_connection) { create(:slack_topic_connection, slack_team_id: slack_team.id, slack_channel_id: slack_channel.id, topic_id: topic.id, domain_id: domain.id, user_id: user.id) }
        
        before do
          post :get_slack_data, {teamId: slack_team.id}, format: :json
        end

        it { expect(json[:topics]).not_to be_empty  }
        it { expect(json[:channels]).not_to be_empty  }
        it { expect(json[:slack_workspace]).not_to be_empty  }
        it { expect(json[:slack_connections]).not_to be_empty  }
      end

      context 'when teamId is not present' do

        before do
          post :get_slack_data, format: :json
        end

        it { expect(json[:topics]).to be_empty  }
        it { expect(json[:channels]).to be_empty  }
        it { expect(json[:slack_workspace]).to be_empty  }
        it { expect(json[:slack_connections]).to be_empty  }
      end
    end


    describe 'POST #create_topic_connection' do

      let(:topic) { create(:topic, user_id: user.id) }
      let(:slack_channel) { create(:slack_channel, slack_team_id: slack_team.id) }
      let(:slack_team) { create(:slack_team, domain_id: domain.id, user_ids: [user.id], bot: {:bot_user_id=>"UCR6NDCKS", :bot_access_token=>"xoxb-433226453984-435011197223-YIOhgxW6P1nusvH99de3u2LU"}) }
      let(:slack_member) { create(:slack_member, slack_team_id: slack_team.id) }

      let(:params) do
        {
          connection: {
            teamId: slack_team.id,
            slack_channel_id: slack_channel.id,
            topic_id: topic.id,
          }
        }
      end

      before do
        post :create_topic_connection, params, format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data][:topic_connection]).not_to be_empty }
    end


    describe "POST #remove_topic_connection" do

      let(:topic) { create(:topic, user_id: user.id) }
      let(:slack_channel) { create(:slack_channel, slack_team_id: slack_team.id) }
      let(:slack_team) { create(:slack_team, domain_id: domain.id, user_ids: [user.id], bot: {:bot_user_id=>"UCR6NDCKS", :bot_access_token=>"xoxb-433226453984-435011197223-YIOhgxW6P1nusvH99de3u2LU"}) }
      let(:slack_member) { create(:slack_member, slack_team_id: slack_team.id) }
      let!(:slack_topic_connection) { create(:slack_topic_connection, slack_team_id: slack_team.id, slack_channel_id: slack_channel.id, topic_id: topic.id, domain_id: domain.id, user_id: user.id) }

      let(:params) do
        {
          connection: {
            id: slack_topic_connection.id,
          }
        }
      end
       
      before do
        post :remove_topic_connection, params, format: :json
      end

      it { expect(json[:data][:message]).to eq('topic connection removed') }
    end

    describe "POST #disconnect_from_slack" do

      let!(:topic) { create(:topic, user_id: user.id) }
      let!(:slack_channel) { create(:slack_channel, slack_team_id: slack_team.id) }
      let!(:slack_team) { create(:slack_team, domain_id: domain.id, user_ids: [user.id]) }
      let!(:slack_topic_connection) { create(:slack_topic_connection, slack_team_id: slack_team.id, slack_channel_id: slack_channel.id, topic_id: topic.id, domain_id: domain.id, user_id: user.id) }

      let(:params) do
        {
          id: slack_team.id,
        }
      end

      before do
        post :disconnect_from_slack, params, format: :json
      end
      it { expect(json[:data][:message]).to eq('Workspace disconnect with slack') }
    end
  end
end