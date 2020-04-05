require 'rails_helper'

describe V2::UserProfileController do
  let(:user) { User.first || create(:user, password: '12345678', password_confirmation: '12345678') }
  let(:view) { View.first || create(:view, name: 'grid', kind: 'system') }

  before do
    user
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'

    Fog.mock!
    storage = Fog::Storage.new({
      :aws_access_key_id      => ENV['FOG_AWS_KEY'],
      :aws_secret_access_key  => ENV['FOG_AWS_SECRET'],
      :provider               => 'AWS',
      :region                 => ENV['FOG_AWS_REGION']
    })
    bucket = storage.directories.find { |d| d.key == ENV['FOG_AWS_BUCKET'] }
    if bucket.nil?
      storage.directories.create(:key => ENV['FOG_AWS_BUCKET'], :public => true)
    end

  end

  describe 'POST #show' do
    context 'profile attributes - anyone can read user profile.' do
      before do
        params = {
          id: user.user_profile.id,
          user_id: user.id
        }
        ViewAssignment.create(view_id: view.id, user_id: user.id)
        get :show, params, format: :json
      end

      it { expect(json[:data][:type]).to eql('user_profiles') }
      it { expect(json[:data][:id]).to eql(user.user_profile.id.to_s) }
    end

    context 'profile attributes - as a user cannot update someone else profile' do
      let(:member) { create(:user) }

      before do
        params = {
          id: member.user_profile.id,
          user_id: member.id,
          data: {
            attributes: {
              description: 'Lorem Ipsum dolor sit amet.'
            }
          }
        }

        post :create, params, format: :json
      end

      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end

    context 'profile attributes - as a admin cannot update someone else profile' do
      let(:member) { create(:user) }
      let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

      before do
        user.add_role :admin, domain

        params = {
          id: member.user_profile.id,
          user_id: member.id,
          data: {
            email_notifications: {
              someone_likes_question: 'weekly',
              someone_shared_topic_with_me: 'always',
              someone_shared_question_with_me: 'daily'
            },
            attributes: {
              description: 'Lorem Ipsum dolor sit amet.'
            }
          }
        }

        post :create, params, format: :json
      end

      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end
  end

  TestAfterCommit.with_commits(true) do
    Sidekiq::Testing.disable! do
      describe 'POST #create' do
        context 'profile attributes' do
          before do
            params = {
              id: user.user_profile.id,
              user_id: user.id,
              data: {
                email_notifications: {
                  someone_likes_question: 'weekly',
                  someone_shared_topic_with_me: 'always',
                  someone_shared_question_with_me: 'daily'
                },
                attributes: {
                  description: 'Lorem Ipsum dolor sit amet.',
                  avatar:
                    Rack::Test::UploadedFile.new(
                      File.join(Rails.root, 'spec', 'support', 'images', 'avatar-image.jpg')
                    ),
                  background_image:
                    Rack::Test::UploadedFile.new(
                      File.join(Rails.root, 'spec', 'support', 'images', 'background-image.jpg')
                    )
                }
              }
            }

            post :create, params, format: :json
          end

          it do
            expect(
              UserProfile.find(json[:data][:relationships][:user_profile][:data][:id]).description
            ).to eql('Lorem Ipsum dolor sit amet.')
          end

          it do
            expect(
              UserProfile.find(json[:data][:relationships][:user_profile][:data][:id]).avatar_processing
            ).to eql(true)
          end

          it do
            expect(
              UserProfile.find(json[:data][:relationships][:user_profile][:data][:id]).background_image_processing
            ).to eql(true)
          end

          it do
            user.user_profile.reload
            expect(user.user_profile.settings(:email_notifications).someone_likes_question).to eql('weekly')
            expect(user.user_profile.settings(:email_notifications).someone_shared_topic_with_me).to eql('always')
            expect(user.user_profile.settings(:email_notifications).someone_shared_question_with_me).to eql('daily')
          end
        end

        context 'user attributes' do
          before do
            params = {
              id: user.user_profile.id,
              user_id: user.id,
              data: {
                attributes: {
                  user_attributes: {
                    id: user.id,
                    first_name: 'Dummy',
                    last_name: 'User',
                    email: 'dummyuser@gmail.com',
                    current_password: '12345678'
                  }
                }
              }
            }

            post :create, params, format: :json
          end

          it do
            expect(
              json[:data][:attributes][:first_name]
            ).to eql('Dummy')
          end
          it do
            expect(
              json[:data][:attributes][:last_name]
            ).to eql('User')
          end
          it do
            user.reload
            expect(
              user.email
            ).to eql('dummyuser@gmail.com')
          end
        end

        context 'ui_settings' do
          let(:topic) { create(:topic, user: user) }
          before do
            params = {
              id: user.user_profile.id,
              user_id: user.id,
              data: {
                attributes: {
                  user_attributes: {
                    id: user.id
                  }
                },
                ui_settings: {
                  hex_panel: false,
                  unprioritizedPanelClosed: {
                    "#{topic.id}": true
                  }
                }
              },
              include: 'user_profile'
            }

            post :create, params, format: :json
          end

          it 'returns ui_settings in user_profile' do
            ui_settings = json[:included][0][:attributes][:ui_settings]
            expect(ui_settings).to_not be_nil
          end

          it { expect(user.user_profile.settings(:ui_settings).hex_panel).to be false }
          it { expect(user.user_profile.settings(:ui_settings).unprioritizedPanelClosed[topic.id.to_s]).to be true }
        end
      end
    end
  end
end
