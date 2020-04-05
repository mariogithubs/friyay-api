require 'rails_helper'

describe TipHive do
  describe '.reserved_domain?' do
    before :all do
      Rails.application.eager_load!
    end
    it { expect(described_class.reserved_domain?('www')).to eql true }
    it { expect(described_class.reserved_domain?('api')).to eql true }
    it { expect(described_class.reserved_domain?('api452')).to eql true }
    it { expect(described_class.reserved_domain?('tip')).to eql true }
    it { expect(described_class.reserved_domain?('api321_other')).to eql false }
    it { expect(described_class.reserved_domain?('test_domain')).to eql false }
  end
end
