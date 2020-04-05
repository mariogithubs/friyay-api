module Perishable
  extend ActiveSupport::Concern

  included do
    after_save :enqueue_perishable
  end

  def will_expire
    NotificationMailer.will_expire(id).deliver_now
  end

  def expire
    update_attribute :is_disabled, true
    NotificationMailer.expire(id).deliver_now
  end

  def archive!
    remove_all_labels
    add_archived_label
    update_attributes(is_disabled: true, expiration_date: Time.zone.now)
  end

  def unarchive
    update_attributes(is_disabled: false, expiration_date: nil) if is_disabled?
    remove_all_labels
  end

  def renew
    update_attributes(is_disabled: false, expiration_date: nil) if is_disabled?
    TipExpirationWorker.perform_in(2.days.ago(expiration_date), 'will_expire', "#{id}")
  end

  def expired?
    perishable? && expiration_date <= Time.zone.now
  end

  def perishable?
    expiration_date
  end

  private

  def remove_all_labels
    # Delete the association, not the label!
    label_assignments.destroy_all
  end

  def add_archived_label
    return unless respond_to?(:labels)
    archive_label = Label.try(:archived)
    labels << archive_label if archive_label
  end

  def enqueue_perishable
    return unless self.expiration_date_changed?

    remove_old_jobs

    return unless perishable?

    renew unless expired?

    TipExpirationWorker.perform_in(expiration_date, 'expire', "#{id}")
  end

  def remove_old_jobs
    query = Sidekiq::ScheduledSet.new
    query.select { |job| job.klass == 'TipExpirationWorker' && job.args[1] == "#{id}" }.map(&:delete)
  end
end
