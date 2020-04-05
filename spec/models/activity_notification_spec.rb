require 'rails_helper'

describe ActivityNotification do
  let(:users) { create_list(:user, 3) }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    users.each { |user| user.join(domain) }
  end
  
  it 'filters list of users' do
    domain.domain_members.last.deactivate!

    recipients = ActivityNotification.exclude_old_users(users)
    expect(recipients.length).to eq(2)
    expect(recipients.collect { |recipient| recipient.id }).to_not include(domain.domain_members.last.id)
  end
end
