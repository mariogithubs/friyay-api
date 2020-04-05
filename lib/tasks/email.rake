namespace :email do
  desc 'Send daily digest'
  task send_daily_feed: :environment do
    User.find_each(batch_size: 100) do |user|
      user.generate_tip_feed(days: -1)
    end
  end

  desc 'Send weekly digest'
  task send_weekly_feed: :environment do
    User.find_each(batch_size: 100) do |user|
      user.generate_tip_feed(days: -1)
    end
  end

  desc 'Test for notifications'
  task notifications_report: :environment do
    log_filename = 'notifications_report.log'
    File.delete("log/#{log_filename}") if File.exists?("log/#{log_filename}")

    log = ActiveSupport::Logger.new("log/#{log_filename}")
    start_time = Time.zone.now

    log.info "Daily Activity Feed started at #{start_time}"

    tenant_names = Domain.pluck(:tenant_name)

    log.info "for #{tenant_names.count} tenants"

    tenant_names.each do |tenant|
      Apartment::Tenant.switch(tenant) do
        notifications = Notification.where(is_processed: false, frequency: 'daily', send_email: true)
        log.info "There are #{notifications.count} eligible notifications for #{tenant}"
      end
    end
    log.info "Finished the notifications report at #{Time.zone.now}"
    log.close

    AdminMailer.delay.process_finished('notifications_report', log_filename, "log/#{log_filename}")
  end

  # TODO: activity feed: need to confirm content and flow
  desc 'Send daily feed'
  task send_daily_activity_feed: :environment do
    # Expire old notifications
    # Send new notifications (those created since the last send)p
    # Update email_sent_at

    Notification.expire_old_email_notifications('daily')


    log_filename = 'daily_activity_feed.log'
    log = ActiveSupport::Logger.new("log/#{log_filename}")

    start_time = Time.zone.now

    AdminMailer.notify(
      subject: 'Daily Activity Started',
      body: "We have started the daily activity feed at #{start_time}"
    ).deliver_now

    log.info "Daily Activity Feed started at #{start_time}"

    tenant_names = Domain.pluck(:tenant_name)

    log.info "for #{tenant_names.count} tenants"

    tenant_names.each do |tenant|
      Apartment::Tenant.switch(tenant) do
        notifications = Notification.where(is_processed: false, frequency: 'daily', send_email: true)
        next if notifications.blank?
        log.info "There are #{notifications.count} eligible notifications for #{tenant}"

        user_ids = notifications.pluck(:user_id).uniq
        next if user_ids.blank?

        log.info "Generating feeds for #{tenant}"
        log.info "User IDs: #{user_ids}"

        users = User.where(id: user_ids)
        users.each do |user|
          feed = user.generate_notification_feed('daily')

          next if feed.blank?
          log.info "\n#{user.email} Feed total: #{feed.count}"

          feeds = merge_feed(feed)
          log.info "Feed Unique IDs: #{feeds.count}"

          next unless feeds.present?
          log << "[#{user.id}: #{feeds.count}] "

          feed_ids = remove_private_tips(feeds).map(&:id).uniq
          next unless feed_ids.present?

          NotificationEmailWorker.perform_async(
            'daily_feed_email',
            notification_ids: feed_ids, email: user.email
          )

          feed.update_all(email_sent_at: Time.now)
        end

        log.info "\n"
      end # Tenant
    end
    log.info "Finished the daily activity feed at #{Time.zone.now}"
    log.close

    AdminMailer.delay.process_finished('send_daily_activity_feed', log_filename, "log/#{log_filename}")
  end

  desc 'Send weekly activity feed'
  task send_weekly_activity_feed: :environment do
    tenant_names = Domain.pluck(:tenant_name)

    tenant_names.each do |tenant|
      puts "Generating feeds for #{tenant}"
      Apartment::Tenant.switch(tenant) do
        user_ids = Notification.where(is_processed: false).map(&:user_id).uniq
        users = User.where(id: user_ids)
        users.each do |user|
          feed = user.generate_notification_feed('weekly')
          feeds = merge_feed(feed)

          next unless feeds.present?
          print "[#{user.id}: #{feeds.count}] "

          feed_ids = remove_private_tips(feeds).map(&:id).uniq
          next unless feed_ids.present?

          NotificationEmailWorker.perform_async(
            'weekly_feed_email',
            notification_ids: feed_ids, email: email
          )

          feed.update_all(is_processed: true)
        end
      end # Tenant
      puts "\n"
    end
    AdminMailer.delay.process_finished('send_weekly_activity_feed')
  end

  desc 'Send reminder to invitees'
  task send_invitation_reminder: :environment do
    Domain.all.each do |domain|
      Apartment::Tenant.switch(domain.tenant_name) do
        Invitation.pending.find_each(batch_size: 100) do |invitation|
          if invitation.notify(domain)
            puts "Domain Name : #{domain.name} : Reminder scheduled for #{invitation.email}."
          else
            puts "Domain Name : #{domain.name} : Reminder failed for #{invitation.email}."
          end
        end
      end
    end
  end

  desc 'Send daily activity notification to invitees'
  task send_invitees_daily_activity_feed: :environment do
    tenant_names = Domain.pluck(:tenant_name)

    tenant_names.each do |tenant|
      Apartment::Tenant.switch(tenant) do
        # We don't want to generate activities feed for invitees on public domain
        next if tenant == 'public'

        # Generating activities feed for invitees
        invitation_ids = InvitationActivityNotification
                           .where(is_processed: false)
                           .where('invitation_id IS NOT NULL').pluck(:invitation_id).uniq
        invitations = Invitation.where(id: invitation_ids)
        invitations.find_each do |invitation|
          invitation.generate_feed('daily')
          print "-#{invitation.email}- "
        end
      end # Tenant
    end
  end

  def merge_feed(feed)
    # Currently only merges tips assigned to topics
    feed_without_tips = feed.dup
    feed_without_tips.to_a.delete_if { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }

    merged_feed = []

    # Group tip notifications by topic
    feed.select { |feed_item| feed_item.notifiable.try(:follower).is_a?(Tip) }
      .group_by { |tip_feed_item| tip_feed_item.notifiable.follower.id }
      .each { |_key, group| merged_feed << group.first }

    merged_feed + feed_without_tips
  end

  def remove_private_tips(feed)
    feed_public_tips = feed.dup
    feed_public_tips.to_a
    .delete_if { |feed_item| feed_item.notifiable.try(:commentable).try(:private?) or
                             feed_item.notifiable.try(:votable).try(:private?) or
                             feed_item.notifiable.try(:shareable_object).try(:private?)}
    feed_public_tips
  end  
end
