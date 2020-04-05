require 'rails_helper'

RSpec.describe InvitationActivityNotificationMailer do
  describe 'tipfeed for invitee' do
    # before { InvitationActivityNotification.send('someone_add_tip_to_topic', create(:tip_follow)) }
    #
    # let(:domain_membership) { DomainMembership.last }
    # let(:domain_invitation) { create(:domain_invitation) }
    # let(:notification) { InvitationActivityNotification.last }
    # let(:mail) do
    #   described_class.daily_feed_email(
    #     email: domain_invitation.email,
    #     notification_ids: [notification.id],
    #     invitation_id: domain_invitation.id
    #   )
    # end

    # it 'renders the subject' do
    #   expect(mail.subject).to eql("Daily Summary for #{domain_membership.domain.name} domain")
    # end

    # it 'renders the receiver email' do
    #   expect(mail.to).to eql([notification.email])
    # end

    # it 'renders the sender email' do
    #   expect(mail.from).to eql([ENV['TIPHIVE_EMAIL_ADMIN']])
    # end

    # it 'assigns @new_domain' do
    #   expect(mail.body.encoded).to match(domain_membership.domain.name)
    # end
  end
end
