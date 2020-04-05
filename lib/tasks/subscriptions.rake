namespace :subscriptions do
  desc 'check subscriptions'
  task check_failed_and_active: :environment do
    subscriptions = Subscription.where("stripe_subscription_id IS NOT NULL and domain_id IS NOT NULL")
    subscriptions.each do |subscription|
      stripe_subscription = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
      if stripe_subscription and stripe_subscription.status.present?
        if stripe_subscription.status == "active"
          #restore users      
          subscription.domain.users.each do |user|
            if user.id != subscription.domain.user_id
              domain_member = DomainMembership.where(user_id: user.id, domain_id: subscription.domain.id).first
              if domain_member and domain_member.upgrade_to_role.present?
                domain_member.update_attribute(:upgrade_to_role, nil) 
                user.remove_role(user.roles.current_for_domain(subscription.domain.id).name, subscription.domain)
                user.add_role(domain_member.upgrade_to_role, subscription.domain)
              end
            end
          end 
        else
          #downgrade users
          subscription.domain.users.each do |user|
            if user.id != subscription.domain.user_id
              domain_member = DomainMembership.where(user_id: user.id, domain_id: subscription.domain.id).first
              if domain_member
                domain_member.update_attribute(:upgrade_to_role, user.roles.current_for_domain(subscription.domain.id).name) 
                user.remove_role(user.roles.current_for_domain(subscription.domain.id).name, subscription.domain)
                user.add_role("guest", subscription.domain)
              end
            end
          end 

          #retry to recover payment
          if stripe_subscription.status == "past_due" or stripe_subscription.status == "unpaid" or stripe_subscription.status == "canceled"
            #get unpaid invoices
            invoices = Stripe::Invoice.list(subscription: subscription.stripe_subscription_id)
            if invoices 
              invoices.each do |invoice|
                if invoice.paid == false
                  invoice.pay
                end
              end
            end
          end
        end  
      end  
    end

  end

end

# rake subscriptions:check_failed_and_active
  
  