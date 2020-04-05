require 'rails_helper'

shared_examples_for 'filterable' do
  let(:model) { described_class }

  context 'when blank' do
    it { expect(model.filter.count).to model.all.count }
  end

  context 'when latest' do
    # TODO: NEED FIND THE ASSERTION HERE
    # it { expect(model.filter('latest').count).to eql(...) }
  end

  context 'when filtering by created_by' do
  end

  context 'when filtering by following_user' do
  end

  context 'when filtering by following_topic' do
  end
end

# RSpec.describe Filterable, type: :model do

# end
