require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe V2::DomainsController, type: :controller do
  let(:user) { create(:user, email: 'xavier@test.com') }
  let(:tenant_name) { '' }

  before do
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.headers['X-Tenant-Name'] = tenant_name
    request.host = 'api.tiphive.dev'
  end

  describe 'GET #index' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:domain_one) { create(:domain, name: 'Domain One', user: bob) }
    let(:domain_two) { create(:domain, name: 'Domain Two', user: bob) }
    let(:domain_three) { create(:domain, name: 'Domain Three', user: bob) }
    let(:guest_domain) { create(:domain, name: 'Guest Domain', user: user) }

    context 'when multiple domains' do
      before do
        user.join(domain_one)
        user.join(domain_two)
        get :index, format: :json
      end

      it { expect(json[:data].map { |item| item[:attributes][:name] }).to include(domain_one.name) }
      it { expect(json[:data].map { |item| item[:attributes][:name] }).to_not include(domain_three.name) }
    end

    context 'when guest domain exists' do
      before do
        guest_domain.add_guest(bob)
        get :index, format: :json
      end

      it { expect(json[:data].map { |item| item[:attributes][:name] }).to include(guest_domain.name) }
    end
  end

  describe 'POST search' do
    context 'when filtering domain_name' do
      let(:domain) { create(:domain, name: 'The Apprentice', user: user) }

      before do
        domain
        get :index, filter: { name: 'App' }, format: :json
      end

      it { expect(json[:data].map { |domain| domain[:id] }).to include(domain.id.to_s) }
    end

    context 'when filtering tenant_name' do
      let(:domain) { create(:domain, name: 'The Apprentice', tenant_name: 'notwhatyouthink', user: user) }

      before do
        domain
        get :index, filter: { name: 'not' }, format: :json
      end

      it { expect(json[:data].map { |domain| domain[:id] }).to include(domain.id.to_s) }
    end
  end

  describe 'GET show' do
    let(:domain) { create(:domain, user: user) }

    before :each do
      domain
      get :show, tenant_name: domain.tenant_name, format: :json
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json[:data][:attributes][:name]).to eql(domain.name) }
  end

  TestAfterCommit.with_commits(true) do
    Sidekiq::Testing.disable! do
      describe 'POST create' do
        let(:member) { create(:user) }
        let(:good_domain_attributes) { attributes_for(:domain, tenant_name: 'domain-name-test') }
        let(:bad_domain_attributes_1) { attributes_for(:domain, tenant_name: 'api45') }

        let(:params) do
          {
            data: {
              type: 'domains',
              attributes: good_domain_attributes,
              relationships: {
                domain_permission: {
                  data: {
                    access_hash: {
                      create_topic:     { roles: ['member', 'power'] },
                      edit_topic:       {},
                      destroy_topic:    {},
                      create_tip:       { roles: ['member', 'power'] },
                      edit_tip:         {},
                      destroy_tip:      {},
                      like_tip:         { roles: ['member', 'power'] },
                      comment_tip:      { roles: ['member', 'power'] }
                    }
                  }
                },
                roles: {
                  data: [
                    {
                      user_id: member.id,
                      name: 'admin'
                    }
                  ]
                }
              }
            }
          }
        end

        let(:notification_size) { NotificationWorker.jobs.size }

        context 'when good_domain_attributes' do
          before do
            post :create, data: params[:data], format: :json
          end

          it 'passes these combined expectations' do
            # Combined 2017-09-20 for speed
            expect(json[:errors]).to be_nil
            expect(json[:data][:id]).to_not be_nil
            expect(json[:data][:attributes][:tenant_name]).to eql 'domain-name-test'
            expect(json[:data][:attributes][:join_type]).to eql Domain.join_types.keys.first
            expect(user.has_role?(:admin, Domain.last)).to eql(true)
            expect(json[:data][:relationships][:domain_permission][:data]).to_not be_nil
          end

          it do
            domain = Domain.find json[:data][:id]
            expect(member.has_role? 'admin', domain)
          end
        end

        context 'when reserved domain name' do
          before do
            params[:data][:attributes] = bad_domain_attributes_1
            post :create, data: params[:data], format: :json
          end

          it { expect(json[:errors][:detail]).to include('Domain URL cannot be used') }
        end

        context 'when adding email_domains' do
          before do
            params[:data][:attributes][:email_domains] = ['test.com', 'tiphive.com']
            post :create, data: params[:data], format: :json
          end

          it { expect(Domain.last.email_domains.count).to eql 2 }
        end

        context 'when checking box to allow_invitation_request' do
          before do
            params[:data][:attributes][:allow_invitation_request] = true
            post :create, data: params[:data], format: :json
          end

          it { expect(Domain.last.allow_invitation_request).to be true }
        end
      end # Create

      describe 'PATCH update' do
        let(:user) { create(:user) }
        let(:domain) { create(:domain, user: user, email_domains: ['test.com']) }
        let(:tenant_name) { domain.tenant_name }

        let(:params) do
          {
            data: {
              id: domain.id,
              type: 'domains',
              attributes: {
                name: 'A new domain name',
                join_type: 'open',
                default_view_id: 'GRID'
              }
            }
          }
        end

        before do
          patch :update, id: domain.id, data: params[:data], format: :json
        end

        it 'passes expectations' do
          # Combined 2017-09-20 for speed
          test_domain = Domain.last
          expect(response).to have_http_status(:ok)
          expect(json[:data][:attributes][:name]).to eql 'A new domain name'
          expect(json[:data][:attributes][:default_view_id]).to eql 'GRID'
          expect(test_domain.default_view_id).to eql 'GRID'
          expect(test_domain.join_type).to eql 'open'
        end

        context 'when adding email_domains' do
          before do
            params[:data][:attributes][:email_domains] = ['test.com', 'tiphive.com']
            patch :update, id: domain.id, data: params[:data], format: :json
          end

          it { expect(Domain.find(json[:data][:id]).email_domains.count).to eql 2 }
        end

        context 'when removing email_domains' do
          before do
            params[:data][:attributes][:email_domains] = ['tiphive.com']
            patch :update, id: domain.id, data: params[:data], format: :json
          end

          it { expect(Domain.find(json[:data][:id]).email_domains).to include('tiphive.com') }
        end

        context 'when checking box to allow_invitation_request' do
          before do
            params[:data][:attributes][:allow_invitation_request] = true
            patch :update, id: domain.id, data: params[:data], format: :json
          end

          it { expect(Domain.find(json[:data][:id]).allow_invitation_request).to be true }
        end
      end # Update

      describe 'PATCH update' do
        let(:user) { create(:user) }
        let(:domain) { create(:domain, email_domains: ['test.com']) }

        let(:params) do
          {
            data: {
              id: domain.id,
              type: 'domains',
              attributes: {
                name: 'A new domain name',
                join_type: 'open'
              }
            }
          }
        end

        before do
          patch :update, id: domain.id, data: params[:data], format: :json
        end

        context 'when not authorized' do
          it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
        end

        context 'when authorized' do
          before do
            user.add_role :admin, domain
            patch :update, id: domain.id, data: params[:data], format: :json
          end

          it { expect(json[:data][:type]).to eql('domains') }
        end
      end # update - authorization

      describe 'POST join' do
        let(:bob) { create(:user, first_name: 'Bob') }

        context 'when open' do
          let(:domain) { create(:domain, user: bob, join_type: :open) }

          before do
            post :join, tenant_name: domain.tenant_name, format: :json
          end

          it { expect(response).to have_http_status(:ok) }
          it { expect(json[:data][:type]).to eql 'domains' }
          it { expect(domain.domain_memberships.map(&:user).map(&:email)).to include(user.email) }
        end

        context 'when invitation_required' do
          let(:domain) { create(:domain, user: bob, join_type: :invitation_required) }

          context 'when email_domains are not present' do
            before do
              post :join, tenant_name: domain.tenant_name, format: :json
            end

            it { expect(json[:errors]).to_not be_nil }
            it { expect(domain.domain_memberships.map(&:user).map(&:email)).to_not include(user.email) }
          end

          context 'when email_domains are present' do
            context 'when email is acceptable' do
              before do
                domain.email_domains = ['test.com']
                domain.save
                post :join, tenant_name: domain.tenant_name, format: :json
              end

              it { expect(json[:errors]).to be_nil }

              it 'joins the new member' do
                this_domain = Domain.find(json[:data][:id])
                expect(this_domain.domain_memberships.map(&:user).map(&:email)).to include(user.email)
              end
            end

            context 'when email is not acceptable' do
              before do
                domain.email_domains = ['tiphvie.com']
                domain.save
                post :join, tenant_name: domain.tenant_name, format: :json
              end

              it { expect(json[:errors]).to_not be_nil }
            end
          end
        end

        it { expect(response).to have_http_status(:ok) }
      end

      describe 'POST add_user' do
        let(:bob) { create(:user, first_name: 'bob') }
        let(:tip) { create(:tip, user: user) }

        before do
          # Create the memberships, then leave the domain
          user.add_role(:admin, current_domain)
          bob.join(current_domain)
          bob.follow(tip)
          bob.follow(user)

          membership = MembershipService.new(current_domain, bob)
          membership.leave!

          post :add_user, id: current_domain.id, user_id: bob.id, format: :json
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(bob.following_users).to include(user) }
        it { expect(bob.following_tips).to include(tip) }

        it 'makes bob active' do
          membership = MembershipService.new(current_domain, bob)
          expect(membership.active?).to be true
        end
      end

      describe 'POST remove_user' do
        let(:bob) { create(:user, first_name: 'bob') }

        context 'when not reassigning' do
          before do
            user.join(current_domain, as: 'member')
            user.add_role(:admin, current_domain)
            bob.join(current_domain)

            post :remove_user,
                 id: current_domain.id,
                 user_id: bob.id,
                 format: :json
          end

          it { expect(response).to have_http_status(:ok) }
          it { expect(DomainMember.active.where(id: bob.id).count).to eql 0 }
          it { expect(bob.domain_memberships.where(domain_id: current_domain.id).map(&:active)).to_not include(true) }
        end

        context 'when reassigning content' do
          let(:topic) { create(:topic, user: bob) }
          let(:tip) { create(:tip, user: bob) }
          let(:comment) { tip.comment_threads << create(:comment, user: bob) }
          let(:group) { create(:group, user: bob) }
          let(:label) { create(:label, user: bob, kind: 'private') }
          let(:content) { [topic, tip, comment, group, label] }

          before do
            user.join(current_domain, as: 'member')
            user.add_role(:admin, current_domain)
            bob.join(current_domain)
            content

            post :remove_user,
                 id: current_domain.id,
                 user_id: bob.id,
                 reassign_user_id: user.id,
                 format: :json
          end

          it { expect(response).to have_http_status(:ok) }

          it 'reassigns content' do
            expect(bob.tips.count).to eql 0
            expect(bob.topics.count).to eql 0
            expect(bob.groups.count).to eql 0
            expect(bob.comments.count).to eql 0
            expect(bob.labels.count).to eql 0

            expect(user.tips.count).to eql 1
            expect(user.topics.count).to eql 1
            expect(user.groups.count).to eql 1
            expect(user.comments.count).to eql 1
            expect(user.labels.count).to eql 1
          end
        end
      end
    end # Sidekiq::Testing
  end # TestAfterCommit
end
