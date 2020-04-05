# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  notifier_id     :integer
#  type            :string
#  action          :string
#  notifiable_type :string           indexed => [notifiable_id]
#  notifiable_id   :integer          indexed => [notifiable_type]
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email_sent_at   :datetime
#  read_at         :datetime
#  is_processed    :boolean          default(FALSE)
#  frequency       :string
#  send_email      :boolean          default(TRUE)
#  invitation_id   :integer          indexed
#

class InvitationActivityNotification < Notification
  def self.someone_adds_topic(resource, _opts = {})
    trigger('someone_adds_topic', resource, resource.user)
  end

  def self.someone_add_tip_to_topic(resource, opts = {})
    trigger('someone_add_tip_to_topic', resource, resource.follower.user, opts)
  end

  def self.someone_joins_domain(resource, _opts = {})
    trigger('someone_joins_domain', resource, resource.user)
  end

  def self.trigger(action_name, resource, notifier, _opts = {})
    Rails.logger.info "====> Triggered #{action_name} for Invitation activities notification"
    current_domain = ActivityNotification.current_domain

    # Don't trigger notification if domain is public
    return if current_domain.tenant_name == 'public'

    # Expecting invitations scoped to current domain (tenant)
    Invitation.pending.find_each do |invitation|
      # Don't trigger for guests b/c guests shouldn't know about domain activity
      next if invitation.invitation_type == 'guest'

      Rails.logger.info "====> Fetch activities for invitation to #{invitation.email}..."

      # TODO: Make this a background Job, so we don't have to wait
      # currently when creating a Tip, this gets called
      InvitationActivityNotification.create(
        action: action_name,
        notifier: notifier,
        notifiable: resource,
        frequency: 'daily',
        send_email: true,
        invitation_id: invitation.id
      )
    end
  end
end
