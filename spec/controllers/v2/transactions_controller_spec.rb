require 'rails_helper'
require 'stripe_mock'

RSpec.describe V2::TransactionsController, type: :controller, :live => true do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  include ControllerHelpers::ContextHelpers

  let(:user) { create(:user, first_name: 'Sally', email: "sally@appleseed.com") }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  
  before do
    StripeMock.start

    uri_template = Addressable::Template.new "https://s3-#{ENV['FOG_AWS_REGION']}.amazonaws.com/tiphiveupload/assets/{logo_file}"
    stub_request(:get, uri_template).to_return(body: File.read('spec/fixtures/tiphive-logo.png'))

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

  after { StripeMock.stop }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
    card_token  = stripe_helper.generate_card_token
    customer = Stripe::Customer.create(email: user.email, source: card_token)
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

    Stripe::InvoiceItem.create({
      amount: 1000,
      currency: 'usd',
      customer: customer["id"],
      description: 'Tiphive rspec testing',
    })
    invoice = Stripe::Invoice.create({
      customer: customer["id"],
      billing: 'send_invoice',
      days_until_due: 1,
    })

    @invoice = Stripe::Invoice.retrieve(invoice["id"])
  end

  describe 'GET #index' do
    context 'get all invoices related customer' do
      before do
        subscription = StripeTool.create_subscription(domain.stripe_customer_id, 1, 3, 4, 1, @plan1.stripe_plan_id, @plan2.stripe_plan_id, @plan3.stripe_plan_id,  @plan4.stripe_plan_id)
        dbase_subscription = Subscription.create(stripe_subscription_id: subscription["id"], user_id: user.id, start_date: subscription["created"], tenure: "month")
        get :index, stripe_customer_id: domain.stripe_customer_id, format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'GET #show' do
    context 'get particular invoice details' do
      before do
        get :show, id: @invoice["id"], format: :json
      end
      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
    end
  end

  describe 'GET #pdf' do
    context 'should generate pdf' do
      before do
        get :pdf, id: @invoice["id"], format: :pdf
      end
      it { expect(controller.headers["Content-Transfer-Encoding"]).to eq("binary")}
      it { expect(controller.headers["Content-Type"]).to eq("application/pdf")}
      it { expect(controller.headers["Content-Disposition"]).to eq("attachment; filename=\"invoice.pdf\"")}
    end
  end
end
