class DomainObserver < ActiveRecord::Observer
  def after_create(domain)
    # NotificationWorker.perform_in(1.second, 'add_a_domain', domain.id, domain.class.to_s)
    AdminMailer.delay.domain_created(domain)
  end
end
