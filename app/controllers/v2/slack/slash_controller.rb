module V2
  module Slack
    class SlashController < ApplicationController
      include TipHive
      include SlackActions
      before_action :validate_token!
      before_action :authorize_user!
      before_action :set_header
      after_action :post_msg, only: [:interactive]

      def create
        render_errors('A Slash command was not provided') && return if params[:text].nil?
        command = params[:text].split[0]
        text = params[:text].split[1..-1].join(' ')
        case command
        when 'search'
          results = TipHiveSearch.search(text, resources: Tip)
          return render json: empty_json, status: :ok if results.blank?
          send_response params[:response_url], results_json(results)
        when 'connect'
          return do_connect
        when 'addcard'
          return do_add_card params
        when 'link'
          return link_topics
        when 'help'
          render json: help, status: :ok
        else
          render json: invalid(command), status: :ok
        end
      end

      def get_interactive_params
        payload = JSON.parse params[:payload], symbolize_names: true
      end

      def link_topics
        select_topic = {
          text: "Connect a Topic",
          response_type: "in_channel",
          attachments: [
            {
              text: "Select a Topic",
              fallback: "Interactive message to select topic",
              color: "#3B3155",
              attachment_type: "default",
              callback_id: "topic_connection",
              actions: [
                {
                  name: "topic_selection",
                  text: "Pick a topic...",
                  callback_id: "select_topic_options",
                  type: "select",
                  data_source: "external",
                }
              ]
            }
          ]
        }        
        send_response params[:response_url], select_topic
      end

      def load_options
        payload = get_interactive_params
        case payload[:name]
        when 'topic_selection'
          Apartment::Tenant.switch(@domain.tenant_name) do
            topics = Topic.all
            options = (
              topics.collect do |topic|
                if(payload[:type] == 'dialog_suggestion')
                  {
                    value: topic.id,
                    label: topic.title
                  }
                else 
                  {
                    value: topic.id,
                    text: topic.title
                  }
                end
              end
            )
            return render json: {
              options: options,
              status: :ok
            }
          end
        when 'share_selection'
          search_param = { q: "*", resources: "User,Group", page: {"number"=>"1", "size"=>"999"} }
          search = SearchService.new(@domain, current_user, search_param)
          sharing_items = search.sharing_items
          sharing_options = sharing_items.collect do |item|
            serialized_item = SharingResourceSerializer.new(item).attributes
            {
              label: serialized_item[:name],
              value: serialized_item[:slug]
            }
          end
          default_options = [
            {
              label: "Just Me (Private)",
              value: "private"
            },
            {
              label: "Everyone",
              value: "everyone"
            },
            {
              label: "People I Follow",
              value: "following"
            }
          ]
          render json: {
            options: default_options + sharing_options
          }, status: :ok
        end
      end

      def save_card payload
        data = payload[:submission]
        tip_params = {
          title: data[:card_title],
          body: data[:card_desc],
          expiration_date: nil,
        }
        topic = Topic.find_by(id: data[:topic_selection])
        @tip = current_user.tips.new(tip_params)
        @tip.save
        subtopic = {
          data: {
            id: topic.id,
            type: "topics",
          }
        }
        @tip.follow_multiple_resources(:topic, subtopic, current_user)

        tip_params = {
          data: {
            relationships: {
              user_followers: {
                data: [
                  {
                    id: data[:share_selection],
                    type: "user"
                  }
                ]
              }
            }
          }
        }
        @tip.share_with_all_relationships(tip_params)
      end

      def interactive
        payload = get_interactive_params
        case payload[:callback_id]
        when 'add_card_action'
          do_add_card payload
        when 'save_card'
          save_card payload
        when 'topic_connection'
          create_topic_connection
        end
      end

      def create_topic_connection        
        payload = get_interactive_params
        if payload[:channel][:name] == 'directmessage'
          conversation = conversations_info({ token: @slack_team.access_token, channel: payload[:channel][:id] })
          user = users_info({ token: @slack_team.access_token, user: JSON.parse(conversation.body)['channel']['user'] })
          slack_channel = SlackChannel.find_or_create_by(slack_team_id: @slack_team.id, slack_channel_id: payload[:channel][:id], name: JSON.parse(user.body)['user']['real_name'] )
        else
          slack_channel = SlackChannel.find_or_create_by(slack_team_id: @slack_team.id, slack_channel_id: payload[:channel][:id], name: payload[:channel][:name])
        end
        topic_connection = SlackTopicConnection.new(slack_team_id: @slack_team.id, slack_channel_id: slack_channel.id, topic_id: payload[:actions][0][:selected_options][0][:value], user_id: current_user.id, domain_id: current_domain.id)
        if topic_connection.save
          data = {
            response_type: "in_channel",
            text: "Following topic connected to this channel:",
            attachments: [
                {
                  title: topic_connection.topic.title,
                  title_link: "https://#{domain_host}/topics/#{topic_connection.topic.slug}",
                }
            ]
          }
          send_response payload[:response_url], data
        else
          render json: { text: 'Error in connection, Try again' }, status: :bad_request
        end
      end


      def do_connect
        team_id = params[:team_id]
        user_id = params[:user_id]
        domain =  @slack_team.domain
        return render json: invalid_connect, status: :ok if team_id.blank? or user_id.blank?
        Apartment::Tenant.switch(domain.tenant_name) do
          data = {
            text: "Follow th link below to connect",
            attachments: [
              {
                color: "#3B3155",
                title: "Connect",
                footer: "Friyay",
                text: "To connect, click here - https://#{domain_host}/slack/connect?team_id=#{team_id}&user_id=#{user_id}"
              }
            ]
          }
          render json: data, status: :ok
        end
      end

   

      def invalid_connect
        {
          text: 'Valid data not provided, try again'
        }
      end

      def help
        {
          text: "How to use /friyay",
          attachments: [
            {
              color: "#3B3155",
              title: "Help",
              footer: "Friyay",
              text: "To Search, user `/friyay search <what to search>`\n To Link a topic `/friyay link`\n To Add a new card use `/friyay addcard`\nTo get this help anytime use `/friyay help`."
            }
          ]
        }
      end

      def invalid(command)
        {
          text: "Invalid Command",
          attachments: [
            {
              color: "#3B3155",
              title: "Invalid Command",
              footer: "Friyay",
              text: "`/friyay #{command}` is not a valid command, use `/friyay help` to get help on how to use"
            }
          ]
        }
      end

      private

      def validate_token!
        is_valid_token = false
        if params[:token]
          is_valid_token = params[:token] == ENV['SLACK_VERIFICATION_TOKEN']
        end
        if params[:payload]
          payload = get_interactive_params
          is_valid_token = payload[:token] == ENV['SLACK_VERIFICATION_TOKEN']
        end
        render_errors('Unauthorized!') && return unless is_valid_token
      end

      def authorize_user!
        user_id = params[:payload] ? JSON.parse(params[:payload], symbolize_names: true)[:user][:id] : params[:user_id] 
        if user_id
           Apartment.tenant_names.each do |tenant|
            Apartment::Tenant.switch(tenant) do
              @slack_member = SlackMember.where("slack_member_id =? and user_id is not null", user_id).first
            end
              Apartment::Tenant.switch!(tenant) if @slack_member
              break if @slack_member
          end
        end        
        if not @slack_member
          no_account = { text: "No hive account connected to this slack account, use `/friyay connect` to connect your account" }
          return render json: no_account, status: :ok
        end
        @slack_team = @slack_member.slack_team
        @domain = @slack_team.domain
        sign_in @slack_member.user, store: true
      end

      def empty_json()
        {
          text: "No Cards Found",
          attachments: [
            {
              color: "#3B3155",
              title: "No Cards Found",
              footer: "Friyay",
            }
          ]
        }
      end

      def results_json(results)
        color = ["#f2ab13", "#ee9843", "#a95fd0", "#cf61c4", "#60cf8b", "#5f8ccf", "#7f5ecf", "#3b3155", "#1d182a"]
        {
          response_type: "in_channel",
          text: "Here are the Cards I found: ",
          attachments: (
            results.collect do |result|
              {
                color: color[result.color_index],
                title: result.title,
                title_link: "https://#{domain_host}/cards/#{result.slug}",
                fallback: result.title + " - https://#{domain_host}/cards/#{result.slug}",
                text: result.body ? result.body[0..30].gsub(/\s\w+\s*$/, '...') :  ''
              }
            end
          )
        }
      end

      def set_header
        response.headers['Content-Type'] = 'application/json'
      end

      def domain_host
        return ENV['TIPHIVE_HOST_NAME'] if Apartment::Tenant.current == 'public'

        "#{Apartment::Tenant.current}.#{ENV['TIPHIVE_HOST_NAME']}"
      end

      def post_msg
        payload = get_interactive_params
        if payload[:callback_id] == 'save_card'
          data = {
            channel: payload[:channel][:id],
            token: @slack_team.access_token,
            text: 'New Card Added',
            response_type: 'in_channel',
            attachments: [
              {
                title: @tip.title,
                title_link: "https://#{domain_host}/cards/#{@tip.slug}",
                fallback: @tip.title + " - https://#{domain_host}/cards/#{@tip.slug}",
                text: @tip.body ? @tip.body[0..30].gsub(/\s\w+\s*$/, '...') :  ''
              }
            ].to_json
          }
          post_message data
        end
      end

      def get_command(text)
        text_words = text.split
        return [text_words[0], text_words[1..-1].join(' ')]
      end
    end
  end
end
