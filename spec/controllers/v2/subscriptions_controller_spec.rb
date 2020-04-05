require 'rails_helper'
require 'stripe_mock'

RSpec.describe V2::SubscriptionsController, type: :controller, live: true do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  include ControllerHelpers::ContextHelpers

  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { create(:user, first_name: 'Sally', email: "sally@appleseed.com") }
  let(:admin) { create(:admin, first_name: 'admin', email: "admin@appleseed.com") }
  let(:usertwo) { create(:user, first_name: 'Sally2', email: "sally2@appleseed.com") }

  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) } 

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    user.add_role(:admin, domain)
    admin.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    admin.add_role(:admin, domain)
    usertwo.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    usertwo.add_role(:member, domain)
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'

    #create customer with card token 
    card_token  = stripe_helper.generate_card_token
    customer = StripeTool.create_customer(domain.name, admin.email, card_token)
    domain.update_stripe_card_and_customer(card_token, customer['id'])

    #create stripe plans with database plans
    stripe_helper.create_plan(id: 'basic-user-m', name: 'basic-user-month', amount: 0, interval: "month", currency: "usd")
    p1 = Stripe::Plan.retrieve('basic-user-m')
    stripe_helper.create_plan(id:'power-user-m', name: 'power-user-month', amount: 800, interval: "month", currency: "usd")
    p2 = Stripe::Plan.retrieve('power-user-m')
    stripe_helper.create_plan(id:'admin-user-m', name: 'admin-user-month', amount: 1600, interval: "month", currency: "usd")
    p3 = Stripe::Plan.retrieve('admin-user-m')
    stripe_helper.create_plan(id:'guest-user-m', name: 'guest-user-month', amount: 0, interval: "month", currency: "usd")
    p4 = Stripe::Plan.retrieve('guest-user-m')
    stripe_helper.create_plan(id: 'basic-user-y', name: 'basic-user-year', amount: 0, interval: "year", currency: "usd")
    p5 = Stripe::Plan.retrieve('basic-user-y')
    stripe_helper.create_plan(id:'power-user-y', name: 'power-user-year', amount: 9600, interval: "year", currency: "usd")
    p6 = Stripe::Plan.retrieve('power-user-y')
    stripe_helper.create_plan(id:'admin-user-y', name: 'admin-user-year', amount: 19200, interval: "year", currency: "usd")
    p7 = Stripe::Plan.retrieve('admin-user-y')
    stripe_helper.create_plan(id:'guest-user-y', name: 'guest-user-year', amount: 0, interval: "year", currency: "usd")
    p8 = Stripe::Plan.retrieve('guest-user-y')

    @plan1 = SubscriptionPlan.find_or_create_by(name: p1["name"], amount: 0, interval: p1["interval"], stripe_plan_id: p1["id"])
    @plan2 = SubscriptionPlan.find_or_create_by(name: p2["name"], amount: 8, interval: p2["interval"], stripe_plan_id: p2["id"])
    @plan3 = SubscriptionPlan.find_or_create_by(name: p3["name"], amount: 16, interval: p3["interval"], stripe_plan_id: p3["id"])
    @plan4 = SubscriptionPlan.find_or_create_by(name: p4["name"], amount: 0, interval: p4["interval"], stripe_plan_id: p4["id"])
    @plan5 = SubscriptionPlan.find_or_create_by(name: p5["name"], amount: 0, interval: p5["interval"], stripe_plan_id: p5["id"])
    @plan6 = SubscriptionPlan.find_or_create_by(name: p6["name"], amount: 96, interval: p6["interval"], stripe_plan_id: p6["id"])
    @plan7 = SubscriptionPlan.find_or_create_by(name: p7["name"], amount: 192, interval: p7["interval"], stripe_plan_id: p7["id"])
    @plan8 = SubscriptionPlan.find_or_create_by(name: p8["name"], amount: 0, interval: p8["interval"], stripe_plan_id: p8["id"])
  end

  describe 'POST valid #create month' do
    let(:params) do
      {
        data: {
          attributes: {
            basic_users_count: 3,
            power_users_count: 4,
            admin_users_count: 5,
            guest_users_count: 2,
            tenure: "month"
          }
        }
      }
    end

    context 'attributes and tenure month' do
      before do
        post :create, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'POST valid #create year' do
    let(:params) do
      {
        data: {
          attributes: {
            basic_users_count: 3,
            power_users_count: 4,
            admin_users_count: 5,
            guest_users_count: 2,
            tenure: "year"
          }
        }
      }
    end

    context 'attributes and tenure year' do
      before do
        post :create, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'POST  #create' do
    before do
      SubscriptionPlan.delete_all
    end

    let(:params) do
      {
        data: {
          attributes: {
            basic_users_count: 3,
            power_users_count: 4,
            admin_users_count: 5,
            guest_users_count: 2,
            tenure: "month"
          }
        }
      }
    end
    context 'valid attributes with no plans' do
      before do
        post :create, data: params[:data], format: :json
      end
      it {expect(json[:errors][:detail]).to include('plans are not defined')}
      it { expect(response.status).to eql 422 }
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        data: {
          attributes: {
            basic_users_count: 3,
            power_users_count: 4,
            admin_users_count: 5,
            guest_users_count: 2,
            tenure: "yearly"
          }
        }
      }
    end
    context 'invalid attr' do
      before do
        post :create, data: params[:data], format: :json
      end
      it {expect(json[:errors][:detail]).to include('tenure should be month or year')}
      it { expect(response.status).to eql 422 }
    end
  end

  describe 'PUT #update' do

    let(:params) do
      {
        data: {
          attributes: {
            basic_users_count: 2,
            power_users_count: 4,
            admin_users_count: 5,
            guest_users_count: 2,
          }
        }
      }
    end

    context 'valid attr month' do
      before do
        subscription = StripeTool.create_subscription(domain.stripe_customer_id, 1, 3, 4, 1, @plan1.stripe_plan_id, @plan2.stripe_plan_id, @plan3.stripe_plan_id,  @plan4.stripe_plan_id)
        dbase_subscription = Subscription.create(stripe_subscription_id: subscription["id"], domain_id: domain.id, start_date: subscription["created"], tenure: "month")
        put :update, id: domain.id, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end

    context 'valid attr year' do
      before do
        subscription = StripeTool.create_subscription_with_discount(domain.stripe_customer_id, 1, 3, 4, 1, @plan5.stripe_plan_id, @plan6.stripe_plan_id, @plan7.stripe_plan_id,  @plan8.stripe_plan_id)
        dbase_subscription = Subscription.create(stripe_subscription_id: subscription["id"], domain_id: domain.id, start_date: subscription["created"], tenure: "year")
        put :update, id: domain.id, data: params[:data], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe "POST #upgrade request" do
    before do
      post :upgrade_request, role: "power user", format: :json
    end
    it { expect(response.status).to eql 200 }
    it { expect { post :upgrade_request, role: "power user", format: :json }.to change { ActionMailer::Base.deliveries.count }.by(3) }
  end

  describe 'GET #subscription details from user' do
    before do
      subscription = StripeTool.create_subscription(domain.stripe_customer_id, 1, 3, 4, 1, @plan1.stripe_plan_id, @plan2.stripe_plan_id, @plan3.stripe_plan_id, @plan4.stripe_plan_id)
      dbase_subscription = Subscription.create(stripe_subscription_id: subscription["id"], domain_id: domain.id, start_date: subscription["created"], tenure: "month")
      get :show, id: domain.id, format: :json
    end
    it { expect(response.status).to eql 200 }
  end

end
