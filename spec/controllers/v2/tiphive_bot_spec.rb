require 'rails_helper'

describe V2::TiphiveBotController do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  include ControllerHelpers::ContextHelpers

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #get_tiphive_bot_data' do
    let(:john) { create(:user, first_name: "John", last_name: "Doe", username: "john", password: "pass@123", password_confirmation: "pass@123") }
    let(:jane) { create(:user, first_name: "jane", last_name: "Doe", username: "jane", password: "pass@123", password_confirmation: "pass@123") }
    let!(:tip1) { create(:tip, title: "Tip A", user: user, due_date: Date.today) }
    let!(:tip2) { create(:tip, title: "Tip B", user: user, completion_date: Date.today) }
    let!(:tip3) { create(:tip, title: "Tip C", user: user, start_date: Date.today-3) }
    let!(:tip4) { create(:tip, title: "Tip D", user: user, due_date: Date.today-4, completed_percentage: 0) }
    let!(:tip5) { create(:tip, title: "Tip E", user: user, start_date: Date.today-4, completed_percentage: 0) }

    let!(:tip_assignment1) { create(:tip_assignment, tip_id: tip1.id, assignment_id: john.id, assignment_type: "User") }
    let!(:tip_assignment2) { create(:tip_assignment, tip_id: tip2.id, assignment_id: jane.id, assignment_type: "User") }
    let!(:tip_assignment3) { create(:tip_assignment, tip_id: tip3.id, assignment_id: jane.id, assignment_type: "User") }
    let!(:tip_assignment4) { create(:tip_assignment, tip_id: tip4.id, assignment_id: john.id, assignment_type: "User") }
    let!(:tip_assignment5) { create(:tip_assignment, tip_id: tip5.id, assignment_id: user.id, assignment_type: "User") }

    context 'Get Card weekly status, topic based status and cleanup card status' do
      before do
        user.follow(john)
        get :get_tiphive_bot_data, format: :json
      end

      it { expect(response.status).to eql(200) }
      it { expect(json[:current_day_tip_status][:card_overdue_today][0][:title]).to eql("Tip A") }
      it { expect(json[:current_day_tip_status][:card_complete_today][0][:title]).to eql("Tip B") }
      it { expect(json[:current_day_tip_status][:card_complete_today][0][:assignee]).to eql(["jane"]) }
      it { expect(json[:weekly_tip_status][:card_overdue_weekly][0][:assignee]).to eql(["John"]) }
      it { expect(json[:weekly_tip_status][:card_overdue_weekly][0][:title]).to eql("Tip D") }
      it { expect(json[:any_assignee_cards_weekly_status][:card_unstarted_weekly][0][:assignee]).to eql(["Sally"]) }
      it { expect(json[:any_assignee_cards_weekly_status][:card_unstarted_weekly][0][:title]).to eql("Tip E") }
      it { expect(json[:workspace_card_weekly_status][:card_overdue_weekly][0][:title]).to eql("Tip D") }
      it { expect(json[:workspace_card_weekly_status][:card_unstarted_weekly][0][:assignee]).to eql(["jane"]) }
    end
  end

  describe 'POST #get_bot_data_using_command' do
    let(:topic) { create(:topic, user_id: user.id) }
    let(:john) { create(:user, first_name: "John", last_name: "Doe", username: "john", password: "pass@123", password_confirmation: "pass@123") }
    let(:jane) { create(:user, first_name: "jane", last_name: "Doe", username: "jane", password: "pass@123", password_confirmation: "pass@123") }
    let!(:tip1) { create(:tip, title: "Tip A", user: user, due_date: Time.now) }
    let!(:tip2) { create(:tip, title: "Tip B", user: user, completion_date: Time.now) }
    let!(:tip3) { create(:tip, title: "Tip C", user: user) }
    let!(:tip4) { create(:tip, title: "Tip D", user: user, due_date: Time.now.beginning_of_week-2, completed_percentage: 0) }
    let!(:tip5) { create(:tip, title: "Tip E", user: user, start_date: Time.now.beginning_of_week-2, completed_percentage: 0) }

    let!(:tip_assignment1) { create(:tip_assignment, tip_id: tip1.id, assignment_id: john.id, assignment_type: "User") }
    let!(:tip_assignment2) { create(:tip_assignment, tip_id: tip2.id, assignment_id: jane.id, assignment_type: "User") }
    let!(:tip_assignment3) { create(:tip_assignment, tip_id: tip3.id, assignment_id: jane.id, assignment_type: "User") }
    let!(:tip_assignment4) { create(:tip_assignment, tip_id: tip4.id, assignment_id: john.id, assignment_type: "User") }
    let!(:tip_assignment5) { create(:tip_assignment, tip_id: tip5.id, assignment_id: user.id, assignment_type: "User") }

    context 'Get get_bot_data_using_command, Card weekly status, user based status, topic based status' do
      before do
        tip1.follow(topic)
        tip2.follow(topic)
        tip3.follow(topic)
        tip4.follow(topic)
        tip5.follow(topic)
      end
      context "while topic selected" do
        context 'while command is status' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {topic_id: topic.id, text: "status" }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:topic_based_cards_status][:card_overdue_weekly][0][:assignee]).to eql(["John"]) }
          it { expect(json[:topic_based_cards_status][:card_overdue_weekly][0][:title]).to eql("Tip D") }
          it { expect(json[:topic_based_cards_status][:card_unstarted_weekly][0][:assignee]).to eql(["Sally"]) }
          it { expect(json[:topic_based_cards_status][:card_unstarted_weekly][0][:title]).to eql("Tip E") }
          it { expect(json[:topic_based_cards_status][:card_in_progress][0][:assignee]).to eql(["Sally"]) }
          it { expect(json[:topic_based_cards_status][:card_in_progress][0][:title]).to eql("Tip E") }
        end

        context 'while command is cards due' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {topic_id: topic.id, text: "cards due" }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:card_overdue_weekly].count).to eql(1) }
          it { expect(json[:card_overdue_weekly][0][:title]).to eql("Tip D") }
          it { expect(json[:card_overdue_weekly][0][:assignee]).to eql(["John"]) }
        end

        context 'while command is cards in progress' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {topic_id: topic.id, text: "cards in progress" }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:card_in_progress_weekly].count).to eql(1) }
          it { expect(json[:card_in_progress_weekly][0][:title]).to eql("Tip E") }
          it { expect(json[:card_in_progress_weekly][0][:assignee]).to eql(["Sally"]) }
        end
      end

      context 'while command is cards this week' do
        before do
          user.follow(john)
          post :get_bot_data_using_command, {topic_id: topic.id, text: "this week" }, format: :json
        end

        it { expect(response.status).to eql(200) }
        it { expect(json[:card_due_this_week].count).to eql(2) }
        it { expect(json[:card_due_this_week][0][:title]).to eql("Tip A") }
        it { expect(json[:card_due_this_week][0][:assignee]).to eql(["John"]) }
      end

      context "while user selected" do
        context 'while command is status' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {user_id: user.id, text: 'status' }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:any_assignee_cards_weekly_status][:card_unstarted_weekly][0][:assignee]).to eql(["Sally"]) }
          it { expect(json[:any_assignee_cards_weekly_status][:card_unstarted_weekly][0][:title]).to eql("Tip E") }
        end
        
        context 'while command is cards due' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {user_id: john.id, text: "cards due" }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:card_overdue_weekly].count).to eql(1) }
          it { expect(json[:card_overdue_weekly][0][:title]).to eql("Tip D") }
          it { expect(json[:card_overdue_weekly][0][:assignee]).to eql(["John"]) }
        end

        context 'while command is cards in progress' do
          before do
            user.follow(john)
            post :get_bot_data_using_command, {user_id: user.id, text: "cards in progress" }, format: :json
          end

          it { expect(response.status).to eql(200) }
          it { expect(json[:card_in_progress_weekly].count).to eql(1) }
          it { expect(json[:card_in_progress_weekly][0][:title]).to eql("Tip E") }
          it { expect(json[:card_in_progress_weekly][0][:assignee]).to eql(["Sally"]) }
        end        
      end
    end
  end
end