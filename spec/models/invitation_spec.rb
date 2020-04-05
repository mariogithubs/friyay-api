require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { expect(build(:invitation, user: build(:user))).to be_valid }
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:invitation_type) }
    it { should validate_presence_of(:email) }
  end
end
