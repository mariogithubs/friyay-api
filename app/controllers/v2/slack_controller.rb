module V2
  class SlackController < ApplicationController
    include HTTParty
    before_action :authorize_domain

    def index
      slack_teams = current_domain.slack_teams
      if slack_teams.length > 0
        render json: slack_teams, each_serializer: SlackTeamSerializer, status: :ok
      else
        render json: { data: "No Slack team integrated yet" }, status: :not_found
      end
    end

    def auth
      data = slack_authenticate
      if data[:ok]
        slack_team, msg = current_domain.add_slack_team(data, current_user)
        if slack_team
          team_name  = slack_team[:team_name]
          invite_slack_users(slack_team) if params[:inviteAllusers]
          user_response = get_slack_user(data[:user_id], data[:access_token])
          slack_memeber = slack_team.add_slack_member(
            user_response[:user], current_user: current_user, integration: true
          ) if user_response[:ok]
          render json: { data: { team_name: team_name, access_token: slack_team.access_token, team_id: slack_team.id }, message: "Slack Team successfully added"}, status: :ok
        else
          render json: { data: msg }, status: :unprocessable_entity
        end
      else
        render json: { data: { message: data[:error] } }, status: :bad_request
      end
    end

    def login
      data = slack_authenticate
      login_or_signup_slack_user(data[:user][:id], data[:access_token])
    end

    def connect
      if params[:email].blank? or params[:password].blank?
        render_errors('Missing email or password parameter.') && return
      end
      
      @user = User.find_for_database_authentication(email: params[:email])
      
      render_errors('Invalid email or password.') && return if not_a_valid_login?
      slack_team, slack_member = find_slack_team(params[:team_id], params[:user_id])
      login_or_signup_slack_user(params[:user_id], slack_team[:access_token])
    end

    def get_user_details
      slack_team, slack_member = find_slack_team(params[:team_id], params[:user_id])
      if slack_member
        return render json: { data: { user_exist: true } }, status: :ok
      end
      user_response = get_slack_user(params[:user_id], slack_team[:access_token])
      if not user_response[:ok]
        return render json: { errors: "Slack User is not valid" }, status: :bad_request
      end
      render json: { data: { user: json_user(user_response[:user]), user_exist: false } }, status: :ok
    end

    def get_slack_data
      slack_teams = current_user.current_domain.slack_teams.where("'#{current_user.id}' = ANY (user_ids)")
      slack_channels = params[:teamId].present? ? get_channels : []
      topics = params[:teamId].present? ? Topic.all : []
      get_topic_connections = params[:teamId].present? ? slack_teams.find(params[:teamId]).slack_topic_connections.where(user_id: current_user.id) : []
      render json: { topics: topics, channels: slack_channels, slack_workspace: slack_teams, slack_connections: get_topic_connections }
    end

    def create_topic_connection
      topic_connection = SlackTopicConnection.new(slack_team_id: params[:connection][:teamId], slack_channel_id: params[:connection][:slack_channel_id], topic_id: params[:connection][:topic_id], user_id: current_user.id, domain_id: current_domain.id)
      if topic_connection.save
        render json: { data: { topic_connection: topic_connection }, message: "Slack Topic connected successfully"}, status: :ok
      else
        render_errors(topic_connection.errors.full_messages)
      end
    end

    def update_topic_connection
      topic_connection = SlackTopicConnection.find(params[:connection][:id])
      if topic_connection.present?
        if topic_connection.update_attributes(slack_channel_id: params[:connection][:slack_channel_id], topic_id: params[:connection][:topic_id]) 
          render json: { data: { topic_connection: topic_connection }, message: "Slack Topic updated successfully"}, status: :ok
        else
          render_errors(topic_connection.errors.full_messages)
        end
      end
    end

    def remove_topic_connection
      topic_connection = SlackTopicConnection.find(params[:connection][:id])
      if topic_connection.present?
        topic_connection.destroy
        render json: { data: { message: "topic connection removed"}}
      end
    end

    def disconnect_from_slack
      slack_team = SlackTeam.find(params[:id])
      if slack_team.present? && slack_team.user_ids.include?("#{current_user.id}")
        slack_team.user_ids.delete("#{current_user.id}")
        slack_team.slack_topic_connections.where(user_id: current_user.id).delete_all
        slack_team.save

        render json: { data: { message: "Workspace disconnect with slack"}}
      else
        render json: { data: { message: "Connection not found"}}
      end
    end

    private

    def authorize_domain
      return render json: {
        errors: ['Slack feature not enabled for public domain.']
      }, status: :not_found unless current_domain.private_domain?
    end

    def slack_authenticate
      slack_options = {
        body: {
          client_id: ENV['SLACK_CLIENT_ID'],
          client_secret: ENV['SLACK_CLIENT_SECRET'],
          code: params[:code],
          redirect_uri: params[:redirectUri]
        }
      }
      slack_response = self.class.post('https://slack.com/api/oauth.access', slack_options)
      JSON.parse slack_response.body, symbolize_names: true
    end

    def json_user(user)
      user_profile = user[:profile]
      {
        first_name: user_profile[:first_name],
        last_name: user_profile[:last_name],
        profile_pic: user_profile[:image_72],
      }
    end

    def get_slack_user(user_id, token)
      slack_options = {
        body: {
          user: user_id,
          token: token
        }
      }
      slack_response = self.class.post('https://slack.com/api/users.info', slack_options)
      JSON.parse slack_response.body, symbolize_names: true
    end

    def find_slack_team(team_id, user_id)
      slack_team = current_domain.slack_teams.find_by({ team_id: team_id })
      slack_member = SlackMember.find_by(slack_member_id: user_id)
      if not slack_team
        return render json: { errors: "Slack Team does not exist" }, status: :bad_request
      end
      return [slack_team, slack_member]
    end

    def not_a_valid_login?
      return true if @user.blank?
      return true if @user.valid_password?(params[:password]) == false
      return true if current_domain.tenant_name == 'public'
      return true unless @user.member_of?(current_domain) || @user.guest_of?(current_domain)

      false
    end

    def login_or_signup_slack_user(user_id, access_token)
      user_response = get_slack_user(user_id, access_token)
      if user_response[:ok]
        slack_member = SlackMember.find_by(slack_member_id: user_response[:user][:id])
        if not slack_member
          slack_team = SlackTeam.find_by(team_id: user_response[:user][:team_id])
          if not slack_team
            return render json: { errors: "Slack Team not integrated with Hive" }, status: :not_found
          end
          slack_member = slack_team.add_slack_member(user_response[:user])
        end
        user = slack_member.user
        sign_in user, store: true
        render json: UserAuthenticatedSerializer.new(user), status: :created, location: [:v2, user]
      else
        render json: { errors: user_response[:error] }, status: :bad_request
      end
    end

    def invite_slack_users(slack_team)
      slack_users_email_ids = get_slack_users_email_ids(slack_team.access_token)
      get_email_status = Invitation.search_emails(slack_users_email_ids) if slack_users_email_ids.present?
      get_email_status.each do |email_status|
        invite_slack_workspace_member_to_tiphive(email_status[:email]) if email_status[:status] == 'not invited yet'
      end
    end

    def get_slack_users_email_ids(access_token)
      headers = {
            'Authorization' => "Bearer #{access_token}",
            'Accept' => 'application/x-www-form-urlencoded',
            'Content-Type' => 'application/x-www-form-urlencoded',
          }
      slack_response = self.class.get('https://slack.com/api/users.list', headers: headers)
      users = JSON.parse slack_response.body, symbolize_names: true
      emails = []
      if users[:ok]  
        users[:members].each do |user|
          emails << user[:profile][:email] if user[:profile][:email].present?
        end
      end
      emails
    end


    def invite_slack_workspace_member_to_tiphive(email)
      invitation_data = {
        attributes: {
          user_id: current_user.id,
          email: email,
          invitation_type: 'domain',
          invitable_type: 'User',
          invitable_id: current_user.id,
          state: 'requested',
          custom_message: "#{current_user.first_name} has requested an invitation."
        }
      }
      invitation = Invitation.create(invitation_data)
    end

    def get_channels
      current_user.current_domain.slack_teams.find(params[:teamId]).slack_channels
    end
  
  end # end of class
end # end of module
