require 'rails_helper'

describe V2::Slack::SlashController do

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }
  let(:params) do
    {
    token: ENV["SLACK_VERIFICATION_TOKEN"],
    team_id: "TCR6NDBUY",
    user_id:"UCR6NDCKS",
    trigger_id: "452392285792.433226453984.4fce8337c06b0fc6eb9bea06a279e3a0",
    response_url: "https://hooks.slack.com/app/TCR6NDBUY/453343952865/QFxppNeWihxct4YzWY1KdB4p"
    }
  end

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'POST #create' do

    context "while searching for cards" do
      let!(:slack_team) { create(:slack_team) }
      let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }

      context 'while searching for card is not present' do

        before do
          current_domain.update_attribute(:user_id, user.id)
          params.merge!({text: 'search test'})
          post :create, params, format: :json
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(json[:text]).to eq("No Cards Found") }
      end


      context 'while Invalid command enter' do

        before do
          current_domain.update_attribute(:user_id, user.id)
          params.merge!({text: 'add-card'})
          post :create, params, format: :json
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(json[:text]).to eq("Invalid Command") }
      end

      context 'while searching for card is present' do
        let!(:tip) { create(:tip, title: "test", user_id: user.id, body: "test")}

        before do
          current_domain.update_attribute(:user_id, user.id)
          params.merge!({text: 'search test'})
          post :create, params, format: :json
        end
        it { expect(response).to have_http_status(:ok) }
      end
    end

    context "for help" do
      let!(:slack_team) { create(:slack_team) }
      let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
      let!(:tip) { create(:tip, title: "test", user_id: user.id, body: "test")}

      before do
        current_domain.update_attribute(:user_id, user.id)
        params.merge!({text: 'help'})
        post :create, params, format: :json
      end
      
      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:text]).to eql("How to use /tiphive") }
      it { expect(json[:attachments][0][:title]).to eql("Help") }
      it { expect(json[:attachments][0][:text]).to eql("To Search, user `/tiphive search <what to search>`\n To Link a topic `/tiphive link`\n To Add a new card use `/tiphive addcard`\nTo get this help anytime use `/tiphive help`.") }
    end

    context "for addcard" do

      before{
      stub_request(:post, "https://slack.com/api/dialog.open").to_return(body: File.read('spec/fixtures/slack_dialog_open.json'))
      }

      context "open dialog" do

        let!(:slack_team) { create(:slack_team) }
        let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
        let!(:tip) { create(:tip, title: "test", user_id: user.id, body: "test")}

        before do
          current_domain.update_attribute(:user_id, user.id)
          params.merge!({text: 'addcard'})
          post :create, params, format: :json
        end
        it { expect(response).to have_http_status(:ok) }
      end
  end

    context "To connect" do
      let!(:slack_team) { create(:slack_team, domain_id: domain.id) }
      let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
      let!(:tip) { create(:tip, title: "test", user_id: user.id, body: "test")}

      before do
        current_domain.update_attribute(:user_id, user.id)
        params.merge!({text: 'connect'})
        post :create, params, format: :json
      end
      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:text]).to eql("Follow th link below to connect") }
      it { expect(json[:attachments][0][:text]).to eql("To connect, click here - https://app.tiphive.test/slack/connect?team_id=TCR6NDBUY&user_id=UCR6NDCKS") }
    end

    context "Link Topic" do
      let!(:slack_team) { create(:slack_team, domain_id: domain.id) }
      let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
      let!(:topic) { create(:topic, title: "test", user_id: user.id) }

      before do
        stub_request(:post, "https://hooks.slack.com/app/TCR6NDBUY/453343952865/QFxppNeWihxct4YzWY1KdB4p").to_return(body: File.read('spec/fixtures/slack_select_response.json'))        
        current_domain.update_attribute(:user_id, user.id)
        params.merge!({text: 'link'})
        post :create, params, format: :json
      end
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST #interactive" do

    before{
      stub_request(:post, "https://slack.com/api/chat.postMessage").to_return(body: File.read('spec/fixtures/slack_post_message_response.json'))
    }

    context "submit dialog" do

      let!(:slack_team) { create(:slack_team) }
      let!(:slack_member) { create(:slack_member, name: 'mukesh', slack_member_id: 'UCR6NDCKS', slack_team_id: slack_team.id, user_id: user.id) }
      let!(:tip) { create(:tip, title: "test", user_id: user.id, body: "test")}
      let!(:parent_topic) { create(:topic, title: 'Parent Topic', user_id: user.id) }
      let!(:topics_to_follow) { create_list(:topic, 3) }

      before do
        current_domain.update_attribute(:user_id, user.id)
        params.merge!({text: 'addcard', payload: 
            "{\"type\":\"dialog_submission\",\"token\":\"#{ENV['SLACK_VERIFICATION_TOKEN']}\",\"action_ts\":\"1539251425.680678\",\"team\":{\"id\":\"TCR6NDBUY\",\"domain\":\"testing-workspace\"},\"user\":{\"id\":\"UCR6NDCKS\",\"name\":\"mukesh\"},\"channel\":{\"id\":\"CCSV9G9QX\",\"name\":\"directmessage\"},\"submission\":{\"card_title\":\"test\",\"card_desc\":\"test asdf \",\"topic_selection\":\"#{parent_topic.id}\",\"share_selection\":\"private\"},\"callback_id\":\"save_card\",\"response_url\":\"https:\\/\\/hooks.slack.com\\/app\\/TCR6NDBUY\\/453343952865\\/QFxppNeWihxct4YzWY1KdB4p\",\"state\":\"saving_card\"}"})
        post :interactive, params, format: :json
      end
      it { expect(response).to have_http_status(:ok) }
    end
  end
end