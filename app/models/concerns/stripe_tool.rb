module StripeTool

  def self.create_customer(domain_name, email, card_token)
    Stripe::Customer.create(email: email, description: "Account related domain #{domain_name}", card: card_token)
  end

  def self.update_customer_card(customer_id, card_token)
    customer = Stripe::Customer.retrieve(customer_id)
    default_card = customer.sources.create({:card => card_token})
    customer.default_source = default_card['id']
    customer.save
  end

  def self.create_subscription(customer_id, basic_users_count, power_users_count, admin_users_count, guest_user_count, plan1, plan2, plan3, plan4)
    Stripe::Subscription.create({
      customer: customer_id,
        items: [
          {
            plan: plan1,
            quantity: basic_users_count.to_i
          },
          {
            plan: plan2,
            quantity: power_users_count.to_i
          },
          {
            plan: plan3,
            quantity: admin_users_count.to_i
          },
          {
            plan: plan4,
            quantity: guest_user_count.to_i
          },

        ]
    })
  end

  def self.create_subscription_with_discount(customer_id, basic_users_count, power_users_count, admin_users_count, guest_user_count, plan1, plan2, plan3, plan4)
    Stripe::Subscription.create({
      customer: customer_id,
      coupon: "10percentOFF", 
      items: [
        {
          plan: plan1,
          quantity: basic_users_count.to_i
        },
        {
          plan: plan2,
          quantity: power_users_count.to_i
        },
        {
          plan: plan3,
          quantity: admin_users_count.to_i
        },
        {
          plan: plan4,
          quantity: guest_user_count.to_i
        },
      ]
    })
  end


  def self.update_subscription(subscription_id, tenure, basic_users_count, power_users_count, admin_users_count, guest_user_count)

    proration_date = Time.now.to_i
    
    subscription = Stripe::Subscription.retrieve(subscription_id)

    plan_position_one = subscription_plan_position(subscription, "basic-user-#{tenure}")
    plan_position_two = subscription_plan_position(subscription, "power-user-#{tenure}")
    plan_position_three = subscription_plan_position(subscription, "admin-user-#{tenure}")
    plan_position_four = subscription_plan_position(subscription, "guest-user-#{tenure}")

    subscription.items = [{
      id: subscription.items.data[plan_position_one.to_i].id,
      plan: subscription_plan_id(subscription, "basic-user-#{tenure}"),
      quantity: basic_users_count
    }]
    subscription.proration_date = proration_date
    subscription.save

    subscription.items = [{
      id: subscription.items.data[plan_position_two.to_i].id,
      plan: subscription_plan_id(subscription, "power-user-#{tenure}"),
      quantity: power_users_count
    }]
    subscription.proration_date = proration_date
    subscription.save

    subscription.items = [{
      id: subscription.items.data[plan_position_three.to_i].id,
      plan: subscription_plan_id(subscription, "admin-user-#{tenure}"),
      quantity: admin_users_count
    }]
    subscription.proration_date = proration_date
    subscription.save

    subscription.items = [{
      id: subscription.items.data[plan_position_four.to_i].id,
      plan: subscription_plan_id(subscription, "guest-user-#{tenure}"),
      quantity: guest_user_count
    }]
    subscription.proration_date = proration_date
    subscription.save
  end
   
  def self.subscription_plan_position(subscription, planName)
    4.times do |n|
      return n if subscription.items.data[n].plan.name.to_s == planName.to_s
    end
  end

  def self.subscription_plan_id(subscription, planName)
    4.times do |n|
      if subscription.items.data[n].plan.name.to_s == planName.to_s
        return subscription.items.data[n].plan.id
      end
    end
  end
  

end
