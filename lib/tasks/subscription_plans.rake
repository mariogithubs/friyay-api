namespace :subscription_plans do
  desc 'Add subscription plans'
  task add: :environment do
    SubscriptionPlan.delete_all

    plan1 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'month',
      name: 'basic-user-month',
      amount: 0,
    })
    SubscriptionPlan.create(name: plan1["name"], interval: "month", amount: 0, stripe_plan_id: plan1["id"] )

    plan2 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'month',
      name: 'power-user-month',
      amount: 800,
    })
    SubscriptionPlan.create(name: plan2["name"], interval: "month", amount: 8, stripe_plan_id: plan2["id"] )

    plan3 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'month',
      name: 'admin-user-month',
      amount: 1600,
    })
    SubscriptionPlan.create(name: plan3["name"], interval: "month", amount: 16, stripe_plan_id: plan3["id"] )

    plan4 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'month',
      name: 'guest-user-month',
      amount: 0,
    })
    SubscriptionPlan.create(name: plan4["name"], interval: "month", amount: 0, stripe_plan_id: plan4["id"] )

    plan5 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'year',
      name: 'basic-user-year',
      amount: 0,
    })
    SubscriptionPlan.create(name: plan5["name"], interval: "year", amount: 0, stripe_plan_id: plan5["id"] )

    plan6 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'year',
      name: 'power-user-year',
      amount: 9600,
    })
    SubscriptionPlan.create(name: plan6["name"], interval: "year", amount: 96, stripe_plan_id: plan6["id"] )

    plan7 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'year',
      name: 'admin-user-year',
      amount: 19200,
    })
    SubscriptionPlan.create(name: plan7["name"], interval: "year", amount: 192, stripe_plan_id: plan7["id"] )

    plan8 = Stripe::Plan.create({
      currency: 'usd',
      interval: 'year',
      name: 'guest-user-year',
      amount: 0,
    })
    SubscriptionPlan.create(name: plan8["name"], interval: "year", amount: 0, stripe_plan_id: plan8["id"] )
  end

  desc 'Add coupon'
  task add_coupon: :environment do
    Stripe::Coupon.create(:percent_off => 10, :duration => 'forever', :id => '10percentOFF')
  end
end  
#rake subscription_plans:add
#rake subscription_plans:add_coupon
