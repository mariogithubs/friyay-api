require 'rails_helper'

describe Topic do
  describe 'attributes' do
    it { should respond_to(:title)}
    it { should respond_to(:description)} 
    it { should respond_to(:parent_id)} 
    it { should respond_to(:default_view_id)} 
    it { should respond_to(:image)}
    it { should respond_to(:remote_image_url)} 
    it { should respond_to(:show_tips_on_parent_topic)} 
    it { should respond_to(:cards_hidden) }
  end

  it 'has a valid factory' do
    expect(build(:topic)).to be_valid
  end

  let(:hive) { create(:topic) }
  let(:hive_with_subtopics) { create(:topic, :with_subtopics, number_of_subtopics: 3) }
  let(:subtopic) { build(:topic, parent: create(:topic)) }

  describe 'ActiveModel validations' do
    # let(:subtopic) { hive_with_subtopics.children.first }

    it { should validate_presence_of(:title) }

    it 'validates uniqueness of hive' do
      hive1 = hive
      hive2 = build(:topic, title: hive1.title)
      expect(hive2).to_not be_valid
    end

    it 'is valid if the hive name is the same as a subtopic' do
      subtopic.update_attribute(:title, 'Superman')
      hive.title = 'Superman'

      expect(hive).to be_valid
    end

    context 'when validating subtopic' do
      let(:sub1) { hive_with_subtopics.children[0] }
      let(:sub2) { hive_with_subtopics.children[1] }
      let(:sub3) { create(:topic, parent_id: hive.id) }

      before do
        sub1.update_attribute(:title, 'Title')
      end

      it 'is valid with different title' do
        sub2.title = 'Title2'

        expect(sub2).to be_valid
      end

      it 'is valid with same title under a different hive' do
        sub3.title = 'Title'

        expect(sub3).to be_valid
      end

      it 'is not valid with same title under same hive' do
        sub2.title = 'Title'

        expect(sub2).to_not be_valid
      end
    end
  end

  describe '#ensure_topic_preference_for' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:mary) { create(:user, first_name: 'Mary') }

    context 'when topic preference exists' do
      let(:topic_preference) { hive.topic_preferences.create(user: bob) }

      before do
        topic_preference
      end

      it { expect(hive.topic_preferences.for_user(bob)).to eql topic_preference }
    end

    context 'when topic_preference does not exist' do
      before do
        # hive.ensure_topic_preference_for(bob)
      end

      it { expect(hive.topic_preferences.for_user(mary)).to be_a(TopicPreference) }
    end
  end

  describe 'something here about testing if the slug gets made from title on save' do
  end

  describe '#subtopic?' do
    it { expect(subtopic.subtopic?).to be(true) }
    it { expect(hive.subtopic?).to be(false) }
  end
end
