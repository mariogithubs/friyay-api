require 'rails_helper'

RSpec.describe NotificationMailer do
  # describe 'join a domain notification to recently joined member' do
  #   let(:mail) { described_class.join_a_domain(notification.id) }
  #   let(:notification) { ActivityNotification.last }
  #   let(:domain_membership) { DomainMembership.last }

  #   before do
  #     ActivityNotification.send('join_a_domain', create(:domain_membership))
  #   end

  #   it 'renders the subject' do
  #     expect(mail.subject).to eql(
  #       "You have successfully joined the #{domain_membership.domain.name} domain on TipHive"
  #     )
  #   end

  #   it 'renders the receiver email' do
  #     expect(mail.to).to eql([notification.user.email])
  #   end

  #   it 'renders the sender email' do
  #     expect(mail.from).to eql([ENV['TIPHIVE_EMAIL_ADMIN']])
  #   end

  #   it 'assigns @new_domain' do
  #     expect(mail.body.encoded).to match(domain_membership.domain.name)
  #   end
  # end
end
