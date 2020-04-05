require 'rails_helper'

RSpec.describe InvitationMailer do
  describe 'domain invitation to new user' do
    let(:invitation) { create(:domain_invitation) }
    let(:mail) { described_class.domain(invitation.id) }

    it 'renders the subject' do
      expect(mail.subject).to eql("You are invited to join the #{invitation.domain_name} workspace on TipHive")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([invitation.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['TipHive@tiphive.com'])
    end

    it 'assigns @new_domain' do
      expect(mail.body.encoded).to match(invitation.hosturl)
    end

    it 'assigns @invitation_url' do
      expect(mail.body.encoded).to include(
        "join?invitation_token=#{invitation.invitation_token}"
      )
    end

    it 'includes the invitee email' do
      expect(mail.body.encoded).to include(
        "#{invitation.email}"
      )
    end
  end

  # describe 'domain invitation to existing member' do
  #   let(:member) { create(:member) }
  #   let(:domain) { create(:domain) }
  #   let(:invitation) do
  #     Invitation.create(
  #       invitation_type: 'domain',
  #       invitable: domain,
  #       email: member.email,
  #       user: domain.user
  #     )
  #   end
  #   let(:mail) { described_class.domain(invitation.id) }

  #   it 'renders the subject' do
  #     expect(mail.subject).to eql("You are invited to join #{invitation.invitable.name}.")
  #   end

  #   it 'renders the receiver email' do
  #     expect(mail.to).to eql([invitation.email])
  #   end

  #   it 'renders the sender email' do
  #     expect(mail.from).to eql([invitation.from_email])
  #   end

  #   it 'assigns @new_domain' do
  #     expect(mail.body.encoded).to match(invitation.hosturl)
  #   end

  #   it 'assigns @connect_url' do
  #     expect(mail.body.encoded).to include(
  #       "http://app.tiphive.com/invitations/#{invitation.invitation_token}/connect"
  #     )
  #   end
  # end

  describe 'account invitation to new user' do
    let(:domain) { create(:domain) }
    let(:invitation) { create(:invitation) }
    let(:mail) { described_class.account(invitation.id) }

    it 'renders the subject' do
      expect(mail.subject).to eql("You are invited to join #{invitation.invitable.name} on TipHive")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([invitation.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['TipHive@tiphive.com'])
    end

    # it 'assigns @new_domain' do
    #   host = 'app' + '.' + ENV['TIPHIVE_HOST_NAME']
    #   expect(mail.body.encoded).to match(host)
    # end

    it 'assigns @invitation_url' do
      expect(mail.body.encoded).to include(
        "join?invitation_token=#{invitation.invitation_token}"
      )
    end
  end

  # describe 'account invitation to existing member' do
  #   let(:user) { create(:user) }
  #   let(:member) { create(:member) }
  #   let(:domain) { create(:domain) }
  #   let(:invitation) do
  #     Invitation.create(
  #       invitation_type: 'domain',
  #       invitable: user,
  #       email: member.email,
  #       user: domain.user
  #     )
  #   end
  #   let(:mail) { described_class.account(invitation.id) }

  #   it 'renders the subject' do
  #     expect(mail.subject).to eql("You are invited to join #{invitation.invitable.name}.")
  #   end

  #   it 'renders the receiver email' do
  #     expect(mail.to).to eql([invitation.email])
  #   end

  #   it 'renders the sender email' do
  #     expect(mail.from).to eql([invitation.from_email])
  #   end

  #   it 'assigns @new_domain' do
  #     expect(mail.body.encoded).to match(invitation.hosturl)
  #   end

  #   it 'assigns @connect_url' do
  #     expect(mail.body.encoded).to include(
  #       "http://app.tiphive.com/invitations/#{invitation.invitation_token}/connect"
  #     )
  #   end
  # end
end
