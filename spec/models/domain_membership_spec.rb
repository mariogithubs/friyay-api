require 'rails_helper'

RSpec.describe DomainMembership, type: :model do
  TestAfterCommit.with_commits(true) do
    Sidekiq::Testing.disable! do
      describe 'join a domain notification' do
        let(:domain_membership) { create(:domain_membership) }
        let(:member) { create(:member) }

        context 'when user joins domain' do
          before do
            member.join(domain_membership.domain)
          end

          it 'creates notification' do
            options = ['join_a_domain', described_class.last.id, 'DomainMembership']

            expect(NotificationWorker.jobs.last['args']).to eql(options)
          end
        end # context
      end # describe
    end # Sidekiq::Testing
  end # TestAfterCommit
end
