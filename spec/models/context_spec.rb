require 'rails_helper'

RSpec.describe Context, type: :model do
  # describe 'associations' do
  #   it { should belong_to(:topic) }
  #   it { should belong_to(:user) }
  # end

  describe 'add_path' do
    it { expect(::Context.add_path('', 'user', 1)).to eql 'user:1' }
    it { expect(::Context.add_path(nil, 'user', 1)).to eql 'user:1' }
    it { expect(::Context.add_path('user:1', 'domain', '2')).to eql 'user:1:domain:2' }
    it { expect(::Context.add_path('user:1', 'domain')).to eql 'user:1' }
    it { expect(::Context.add_path('user:1', 'domain', nil)).to eql 'user:1' }
    it { expect(::Context.add_path('user:1', 'domain', '')).to eql 'user:1' }
  end

  describe 'generate_id' do
    let(:user) { build(:user, id: 1) }
    let(:domain) { build(:domain, id: 34) }
    let(:topic) { build(:topic, id: 56) }

    it 'creates the correct context id string' do
      resource_hash = { user: user.id, domain: domain.id, topic: topic.id }

      expect(::Context.generate_id(resource_hash)).to eql 'user:1:domain:34:topic:56'
    end
  end
end
