require 'rails_helper'

describe Comment do
  it 'has a valid factory' do
    expect(build(:tip)).to be_valid
  end
  # These tests only cover what isn't covered in the gem
  describe 'attributes' do
    it { is_expected.to have_attribute(:longitude) }
    it { is_expected.to have_attribute(:latitude) }
    it { is_expected.to have_attribute(:address) }
    it { is_expected.to have_attribute(:location) }
  end

  describe 'parsing' do
    # do something like this only with mentions
    # Tip.new(body: 'http://www.apple.com').send('parse_me', Parse::URL_REGEXP)
    # and expect [[], ["http://www.apple.com"]]
    # first one is blank b/c its a new Tip and didn't have a previous body
    # the previous body is used to only create mentions for new entries

    it 'parses lowercase mentions' do
      comment = described_class.new(body: '<span>@alassiter</span>')
      expect(comment.send('parse_mentions', Parse::MENTION_REGEXP)[1]).to eql ['alassiter']
    end

    it 'parses uppercase mentions' do
      comment = described_class.new(body: '<span>@ALASSITER</span>')
      expect(comment.send('parse_mentions', Parse::MENTION_REGEXP)[1]).to eql ['alassiter']
    end

    it 'does not parse emails' do
      comment = described_class.new(body: '<span>anthony@tiphive.com</span>')
      expect(comment.send('parse_mentions', Parse::MENTION_REGEXP)[1]).to eql []
    end
  end
end
