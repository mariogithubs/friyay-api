require 'rails_helper'

describe V2::TipsController do
  include LinkHelpers
  include ControllerHelpers::JsonHelpers
  include ControllerHelpers::ContextHelpers

  let(:user) { create(:user, first_name: 'Sally') }
  let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

  before do
    user.join(Domain.find_by(tenant_name: Apartment::Tenant.current))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'

    uri_template = Addressable::Template.new "https://api-us2.pusher.com/apps//events?auth_key={key}&auth_signature={signature}&auth_timestamp={timestmp}&auth_version=1.0&body_md5={md5}"
    stub_request(:post, uri_template)

  end

  describe 'GET #index' do
    let(:tip_list) { create_list(:tip, 5, user: user) }
    let(:private_tip) { create(:tip, share_public: false, user: user) }
    let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1) }

    context 'when no filter or include' do

      before do
        tip_list.first(3).each do |tip|
          tip.follow(topic)
        end

        tip_list.last(2).each do |tip|
          tip.follow(topic.children[0])
        end

        get :index, format: :json
      end

      it { expect(response).to have_http_status(:success) }

      it 'returns list of following tips' do
        expect(json[:data].count).to eql(5)
      end
    end

    context 'when user is not an active member' do
      before do
        user.leave(current_domain)

        get :index, format: :json
      end

      it { expect(json[:errors]).to include("You are not a member of #{current_domain.tenant_name}.friyayapp.io") }
    end

    context 'when user is guest' do
      let(:guest) { create(:user) }
      before do
        tip_list
        guest.join(current_domain, as: 'guest')
        request.headers['Authorization'] = "Bearer #{guest.auth_token}"

        tip_list.first(3).each {|tip| tip.share_with_singular_user_resource(guest)}

        get :index, format: :json
      end

      it 'should retrieve tips' do
        expect(json[:data].count).to eq 3
      end

    end

    context 'when default sort order' do
      before do
        tip_list.each_with_index do |tip, index|
          tip.update_attribute(:created_at, tip.created_at - (index + 1).months)
        end

        get :index, format: :json
      end

      it { expect(json[:data].first[:attributes][:created_at].to_date).to eql(Time.zone.today - 1.months) }
      it { expect(json[:data].last[:attributes][:created_at].to_date).to eql(Time.zone.today - 5.months) }
    end

    context 'when asking to sort by most recent' do
      before do
        tip_list.each_with_index do |tip, index|
          tip.update_attribute(:created_at, tip.created_at - (index + 1).months)
        end

        get :index, sort: 'created_at', format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data].last[:attributes][:created_at].to_date).to eql(Time.zone.today - 1.months) }
      it { expect(json[:data].first[:attributes][:created_at].to_date).to eql(Time.zone.today - 5.months) }
    end

    context 'when filtering by user_id (a user profile)' do
      let(:bob) { create(:user, first_name: 'Bob') }

      before do
        tip_list.each do |tip|
          tip.update_attribute(:user_id, bob.id)
          user.stop_following(tip)
          user.remove_role(:admin, tip)
        end

        private_tip.update_attribute(:user_id, bob.id)
        user.stop_following(private_tip)
        user.remove_role(:admin, private_tip)
      end

      context 'when a member is viewing profile' do
        before do
          get :index, user_id: bob.id, format: :json
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(json[:data].count).to eql(tip_list.count) }
      end

      context 'when a guest is viewing profile' do
        before do
          user.leave(current_domain)
          user.join(current_domain, as: 'guest')

          tip_list.last(2).each { |tip| tip.share_with_singular_user_resource(user) }

          get :index, user_id: bob.id, format: :json
        end

        it { expect(Tip.count).to eql 6 }
        it { expect(json[:data].count).to eql 2 }
      end
    end

    context 'when filtering by topic' do
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1) }

      before do
        tip_list.first(3).each do |tip|
          tip.follow(topic)
        end

        tip_list.last(2).each do |tip|
          tip.follow(topic.children[0])
        end
      end

      context 'when no view_id is given' do
        before do
          get :index, topic_id: topic.id, format: :json
        end

        it { expect(json[:data].count).to eql(5) }
      end
    end

    context 'when filtering by group' do
      let(:group) { create(:group) }
      let(:topic) { create(:topic) }

      before do
        group.follow(topic)
        tip_list.each { |tip| tip.follow(topic) }

        tip_list.first(3).each do |tip|
          group.follow(tip)
        end

        get :index, filter: { within_group: group.id }, format: :json
      end

      it { expect(json[:data].count).to eql(3) }
    end

    context 'when filtering by starred' do
      before do
        tip_list.first(3).each do |tip|
          VoteService.add_vote(user, tip, :star)
        end

        get :index, filter: { type: 'starred' }, format: :json
      end

      it { expect(json[:data].count).to eql(3) }
    end

    context 'when filtering by Topics I follow' do
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1) }
      let(:topic2) { create(:topic) }

      context 'outside a group' do
        before do
          user.follow(topic)

          tip_list.first(3).each do |tip|
            tip.follow(topic)
          end

          get :index, filter: { topics: 'following' }, format: :json
        end

        it { expect(json[:data].count).to eql 3 }
      end

      context 'inside a group' do
        let(:group) { create(:group) }

        before do
          user.join(group)
          user.follow(topic2)
          group.follow topic2

          tip_list.first(5).each do |tip|
            tip.follow(topic2)
          end

          tip_list.first(2).each do |tip|
            group.follow(tip)
          end

          get :index, filter: { within_group: group.id, topics: 'following' }, format: :json
        end

        it { expect(json[:data].count).to eql 2 }
      end
    end

    context 'when filtering by Topics I Do Not follow' do
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1) }

      before do
        user.follow(topic)
        tip_list.first(3).each do |tip|
          tip.follow(topic)
        end

        get :index, filter: { topics: 'not_following' }, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end

    context 'when filtering by assignment' do
      before do
        tip_list.first(3).each do |tip|
          tip.assigned_users << user
        end

        get :index, filter: { assigned_to: user.id }, format: :json
      end

      it { expect(json[:data].count).to eql 3 }
    end

    context 'when filtering by label' do
      context 'when label is archive' do
        before do
          tip_list.first.labels << Label.archived
          tip_list.first.archive!

          get :index, filter: { labels: "#{Label.archived.id}" }, format: :json
        end

        it { expect(Tip.archived.count).to eql 1 }
        it { expect(json[:data].count).to eql 1 }
      end

      context 'when page 2' do
        let(:blue_list) { create_list(:tip, 20, user: user) }
        let(:green_list) { create_list(:tip, 20, user: user) }
        let(:blue_label) { create(:label, name: 'Blue') }
        let(:green_label) { create(:label, name: 'Green') }

        before do
          blue_list.each { |tip| tip.labels << blue_label }
          green_list.each { |tip| tip.labels << green_label }

          get :index,
              filter: { labels: "#{blue_label.id}" },
              page: { number: 2, size: 15 },
              format: :json
        end

        it { expect(json[:data].count).to eql 5 }
      end
    end

    context 'when custom order exists' do
      let(:aaa) { create(:tip, title: 'aaa', user: user) }
      let(:bbb) { create(:tip, title: 'bbb', user: user) }
      let(:ccc) { create(:tip, title: 'ccc', user: user) }
      let(:topic) { create(:topic, user: user) }
      let(:bob) { create(:user, first_name: 'Bob') }

      before do
        [aaa, bbb, ccc].each do |tip|
          tip.follow(topic)
        end

        context_id = Context.generate_id(
          user: user.id,
          domain: current_domain.id,
          topic: topic.id
        )

        user_context = Context.create(context_uniq_id: context_id, default: false)

        [ccc, bbb, aaa].each_with_index do |tip, index|
          user_context.context_tips.create(tip_id: tip.id, position: index + 1)
        end

        context_id = Context.generate_id(
          user: bob.id,
          domain: current_domain.id,
          topic: topic.id
        )

        bob_context = Context.create(context_uniq_id: context_id, default: true)

        [ccc, aaa, bbb].each_with_index do |tip, index|
          bob_context.context_tips.create(tip_id: tip.id, position: index + 1)
        end
      end

      context 'when current_user has context' do
        before do
          get :index, topic_id: topic.id, format: :json
        end

        it 'returns the order user specified' do
          expect(json[:data].map { |tip| tip[:attributes][:title] }).to eql(%w(ccc bbb aaa))
        end
      end

      context 'when current_user does not have a context' do
        before do
          context_id = Context.generate_id(
            user: user.id,
            domain: current_domain.id,
            topic: topic.id
          )

          user_context = Context.find_by(context_uniq_id: context_id)
          user_context.destroy

          get :index, topic_id: topic.id, format: :json
        end

        it 'returns the order user specified' do
          expect(json[:data].map { |tip| tip[:attributes][:title] }).to eql(%w(ccc aaa bbb))
        end
      end

      context 'when passing bobs context' do
        before do
          context_id = Context.generate_id(
            user: bob.id,
            domain: current_domain.id,
            topic: topic.id
          )

          get :index, topic_id: topic.id, context_id: context_id, format: :json
        end

        it 'returns the order bob specified' do
          expect(json[:data].map { |tip| tip[:attributes][:title] }).to eql(%w(ccc aaa bbb))
        end
      end
    end
  end

  describe 'GET #index (nested_tips)' do
    let(:topic) { create(:topic, user: user) }
    let(:parent_tip) { create(:tip, title: 'Parent Tip', user: user) }
    let(:child1) { create(:tip, title: 'AAA', user: user) }
    let(:child2) { create(:tip, title: 'BBB', user: user) }
    let(:child3) { create(:tip, title: 'CCC', user: user) }

    before do
      parent_tip.follow(topic)
      [child1, child2, child3].each { |child| child.follow(parent_tip) }
    end

    context 'when tips have nested tips' do
      before do
        get :index, topic_id: topic.id, include: 'nested_tips', format: :json
      end

      it { expect(json[:data].map { |tip| tip[:id] }).to include(parent_tip.id.to_s) }

      it 'returns nested tips in default order' do
        first_tip = json[:data].find { |tip| tip[:id] == parent_tip.id.to_s }
        nested_tips = first_tip[:relationships][:nested_tips]
        correct_order = [child1.id, child2.id, child3.id].map(&:to_s).reverse
        expect(nested_tips[:data].map { |tip| tip[:id] }).to eql correct_order
      end

      it 'has correct included attributes' do
        expect(json[:included].first[:attributes][:liked_by_current_user]).to_not be_nil
        expect(json[:included].first[:attributes]).to have_key(:position)
      end
    end

    context 'when reordering nested tips' do
      before do
        ReorderService.new(
          user: user,
          domain: current_domain,
          resource: child3,
          topic_id: topic.id,
          tip_id: parent_tip.id,
          preceding_resources: [child1.id]
        ).reorder

        get :index, topic_id: topic.id, include: 'nested_tips', format: :json
      end

      it 'returns nested tips in new order' do
        first_tip = json[:data].find { |tip| tip[:id] == parent_tip.id.to_s }
        nested_tips = first_tip[:relationships][:nested_tips]
        correct_order = [child1.id, child3.id, child2.id].map(&:to_s)
        expect(nested_tips[:data].map { |tip| tip[:id] }).to eql correct_order
      end
    end
  end

  with_versioning do
    describe 'GET #index' do
      let(:tip) { create(:tip) }
      let(:tip_list) { create_list(:tip, 5, user: user) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1) }

      context 'index do not load versions' do

        before do
          tip_list.first(3).each do |tip|
            tip.follow(topic)
          end
          tip.update_attribute(:body, "this is new body")
          get :index, format: :json
        end

        it { expect(response).to have_http_status(:success) }
        it { expect(json[:data][0][:relationships][:versions][:data].count).to eql(0) }
      end
    end
  end

  describe 'GET /topics/:topic_id/tips' do
    let(:topic) { create(:topic) }
    let(:topic_with_children) { create(:topic, :with_subtopics, number_of_subtopics: 1) }
    let(:tip_list) { create_list(:tip, 5, user: user) }

    context 'when there are tips in subtopics' do
      before do
        tip_list.first(3).each do |tip|
          tip.follow(topic_with_children)
        end

        tip_list.last(2).each do |tip|
          tip.follow(topic_with_children.children[0])
          tip.stop_following(topic_with_children) # Trying to not require following parent
        end

        get :index, topic_id: topic_with_children.id, format: :json
      end

      it { expect(json[:data].count).to eql(5) }
    end

    context 'when there are public and private tips' do
      let(:sally) { create(:user, first_name: 'Sally') }
      let(:sallys_public_tips) { create_list(:tip, 2, user: sally, share_public: true) }
      let(:sallys_private_tips) { create_list(:tip, 1, user: sally, share_public: false) }

      before do
        sallys_public_tips.each do |tip|
          tip.follow(topic)
        end

        sallys_private_tips.each do |tip|
          tip.follow(topic)
        end

        get :index, topic_id: topic.id, format: :json
      end

      it 'only shows public tips by default' do
        expect(json[:data].count).to eql(2)
      end

      context 'when there are also share_following tips' do
        let(:sallys_following_tips) { create_list(:tip, 4, user: sally, share_following: true) }

        context 'when user is following Sally' do
          before do
            sallys_following_tips.each do |tip|
              tip.follow(topic)
            end

            user.follow(sally)
            sally.follow(user)

            get :index, topic_id: topic.id, format: :json
          end

          it 'shows public tips and shared_following tips' do
            expect(json[:data].count).to eql(6)
          end
        end

        context 'when user is NOT following Sally' do
          before do
            sallys_following_tips

            get :index, topic_id: topic.id, format: :json
          end

          it 'only shows public tips' do
            expect(json[:data].count).to eql(2)
          end
        end
      end

      context 'when there are also tips the user owns' do
        let(:my_tips) { create_list(:tip, 3, user: user, share_public: false) }

        before do
          my_tips.each do |tip|
            tip.follow(topic)
          end

          get :index, topic_id: topic.id, format: :json
        end

        it 'shows public tips and owned tips' do
          expect(json[:data].count).to eql(5)
        end
      end
    end

    context 'when filtering by label' do
      context 'when label is archive' do
        before do
          tip_list.each do |tip|
            tip.follow(topic)
          end

          tip_list.first.labels << Label.archived
          tip_list.first.archive!

          get :index, topic_id: topic.id, filter: { labels: "#{Label.archived.id}" }, format: :json
        end

        it { expect(Tip.archived.count).to eql 1 }
        it { expect(json[:data].count).to eql 1 }
      end
    end
  end

  describe 'GET /users/:user_id/tips' do
    let(:bob) { create(:user, first_name: 'bob') }
    let(:bobs_tips) { create_list(:tip, 3, user: bob, share_public: true) }

    before do
      bobs_tips
      user.follow(bob)

      get :index, user_id: bob.id, format: :json
    end

    it { expect(json[:data].count).to eql(3) }
  end

  describe 'GET #index guest scenarios' do
    let(:bob) { create(:user, first_name: 'Bob') }
    let(:harry) { create(:user, first_name: 'Harry') }
    let(:group_followed) { create(:group, user: bob) }
    let(:topic_followed) { create(:topic, user_id: bob.id) }
    let(:topic_not_followed) { create(:topic, user: bob) }
    let(:tip) { create(:tip, user: bob) }
    let(:private_tip) { create(:tip, user: bob, share_public: false) }
    let(:tip_shared_by_bob_with_followers) { create(:tip, user: bob, share_public: false, share_following: true) }
    let(:tip_shared_by_harry_with_followers) { create(:tip, user: harry, share_public: false, share_following: true) }

    context 'with tips' do
      before do
        # Change current_domain owner so user is guest
        current_domain.update_attribute(:user_id, bob.id)
        current_domain.reload

        user.leave(current_domain)
        user.join(current_domain, as: 'guest')
        user.follow(bob)
        bob.follow(user)
      end

      context 'shared with guest' do
        before do
          tip.share_with_singular_user_resource(user)
          private_tip

          get :index, format: :json
        end

        it { expect(user.following?(tip)).to be true }
        it { expect(json[:data].count).to eql 1 }
        it { expect(json[:data].first[:id]).to eql tip.id.to_s }
      end

      context 'shared with groups the guest follows' do
        before do
          user.follow(group_followed)
          tip.share_with_singular_user_resource(group_followed)

          get :index, format: :json
        end

        it { expect(json[:data].first[:id]).to eql tip.id.to_s }
      end
    end

    context 'with tips not to be seen' do
      before do
        # Change current_domain owner so user is guest
        current_domain.update_attribute(:user_id, bob.id)
        current_domain.reload

        user.leave(current_domain)
        user.join(current_domain, as: 'guest')
        user.follow(bob)
        bob.follow(user)
      end

      context 'in topics shared with groups the guest follows' do
        before do
          user.follow(group_followed)
          tip.follow(topic_not_followed)
          group_followed.follow(topic_not_followed)

          get :index, format: :json
        end

        it { expect(json[:data].count).to eql 0 }
      end

      context 'when in a topic a guest follows, that the group also follows' do
        before do
          user.follow(topic_followed)
          user.follow(group_followed)
          tip.follow(topic_followed)

          get :index, topic_id: topic_followed.id, format: :json
        end

        it { expect(user.has_role?(:guest, current_domain)).to be true }
        it { expect(json[:data].count).to eql 0 }
      end

      context 'in topics followed by guest' do
        before do
          user.follow(topic_followed)
          tip.follow(topic_followed)

          get :index, format: :json
        end

        it { expect(json[:data].count).to eql 0 }
      end

      context 'in topics not followed by guest' do
        before do
          user.follow(topic_followed)
          tip.follow(topic_not_followed)

          get :index, format: :json
        end

        it { expect(json[:data].count).to eql 0 }
      end

      context 'shared with followers by users the guest does not follow' do
        before do
          tip_shared_by_harry_with_followers

          get :index, format: :json
        end

        it { expect(json[:data].count).to eql 0 }
      end

      context 'shared with public' do
        before do
          tip

          get :index, format: :json
        end

        it { expect(json[:data].count).to eql 0 }
      end
    end
  end

  describe 'GET #show' do
    let(:member) { create(:user) }
    let(:tip) { create(:tip, user: member) }

    context 'when given an id' do
      let(:tips) { create_list(:tip, 5, user: user) }

      before :each do
        get :show, id: tips[3], format: :json
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:id]).to eql tips[3].id.to_s }
    end

    context 'when givin a good slug' do
      let(:tip) { create(:tip, user: user) }

      before :each do
        get :show, id: tip.slug, format: :json, uid: user.id
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:id]).to eql tip.id.to_s }
    end

    context 'when givin a bad slug' do
      let(:tip) { create(:tip, user: user) }

      before :each do
        get :show, id: tip.slug + '-bad-slug', format: :json, uid: user.id
      end

      xit { expect(response).to redirect_to(action: :show, id: tip, uid: user.id) }

      it 'matches the path with the good slug' do
        new_slug = URI.parse(response.location).path.split('/').last
        expect(new_slug).to eql tip.slug
      end
    end

    context 'when given blank id' do
      before :each do
        get :show, id: '', format: :json, uid: user.id
      end

      it { expect(response.status).to eql 401 }
      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end

    context 'when including user' do
      let(:tip) { create(:tip, user: user) }

      before do
        get :show, id: tip.slug, include: 'user', format: :json
      end

      skip { expect(json[:included].map { |item| item[:id] }).to include(user.id.to_s) }
    end

    context 'when authorized to read' do
      let(:tips) { create_list(:tip, 5, user: user) }

      before :each do
        get :show, id: tips[3], format: :json, uid: user.id
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:id]).to eql tips[3].id.to_s }
    end

    context 'when tip_followers exist' do
      let(:parent_tip) { tip }
      let(:child_tip) { create(:tip, user_id: member.id) }

      before do
        child_tip.follow(parent_tip)

        get :show, id: parent_tip.slug, format: :json
      end

      it { expect(response).to have_http_status(:success) }
      it { expect(json[:data][:relationships][:nested_tips][:data].count).to eql 1 }
    end
  end

  describe 'GET #show (Share Settings)' do
    let(:member) { create(:user) }
    let(:tip) { create(:tip, user: user) }
    let(:group) { create(:group) }

    let(:params) do
      {
        data: {
          relationships: {
            share_settings: {
              data: [{ id: group.id, type: 'groups' }]
            }
          }
        }
      }
    end

    context 'when shared with a group ONLY' do
      before do
        tip.share_with_all_relationships(params)
        get :show, id: tip.slug, include: 'share_settings', format: :json
      end

      it { expect(json[:data][:relationships][:share_settings][:data].count).to eql 1 }

      it 'includes groups' do
        settings = json[:included].map { |ss| ss[:attributes][:sharing_object_type] }
        expect(settings).to include 'groups'
      end

      it 'does not include users' do
        settings = json[:data][:relationships][:share_settings][:data].map { |ss| ss[:sharing_object_type] }
        expect(settings).to_not include 'users'
      end
    end

    context 'when shareed with a group AND everyone' do
    end
  end

  describe 'POST #create check abilities' do
    let(:bob) { create(:user, email: 'bob@test.com', first_name: 'bob') }
    let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 3, user: user) }
    let(:topic_no_children) { create(:topic, user: user) }

    let(:params) do
      {
        data: {
          type: 'tips',
          attributes: {
            title: FFaker::Lorem.words(rand(1..4)).join(' ').titleize,
            body: FFaker::Lorem.paragraphs(2).join("\n")
          },
          relationships: {
            subtopics: {
              data: [
                { id: topic_no_children.id, type: 'topics' },
                { id: topic.children[0].id, type: 'topics' }
              ]
            }
          }
        }
      }
    end

    before do
      # Change current_domain owner so user is guest
      current_domain.update_attribute(:user_id, bob.id)
      current_domain.reload

      user.leave(current_domain)
      user.join(current_domain, as: 'guest')

      post :create, data: params[:data], format: :json
    end
    # ensure domain allows creating tips
    # create a topic that does not allow creating tips
    # user shouldn't be able to create a tip
    # create a domain that does not allow creating tips
    # create a topic that allows creating tips
    # user shouldn't be able to create a tip
    # create a domain that allows creating tips
    # create a topic, but don't change settings
    # user should be able to create a tip

    xcontext 'when domain does not allow' do
    end

    xcontext 'when domain & topic do not allow' do
    end

    xcontext 'when domain allows and topic does not' do
    end

    xcontext 'when topic allows and domain does not' do
    end
  end

  describe 'POST #create', versioning: true do
    let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 3, user: user) }
    let(:topic_no_children) { create(:topic, user: user) }

    let(:params) do
      {
        data: {
          type: 'tips',
          attributes: {
            title: 'Test Tip',
            body: FFaker::Lorem.paragraphs(2).join("\n")
          },
          relationships: {
            subtopics: {
              data: [
                { id: topic_no_children.id, type: 'topics' },
                { id: topic.children[0].id, type: 'topics' }
              ]
            }
          }
        }
      }
    end

    context 'when valid attributes' do
      context 'when only subtopics are present' do
        before :each do
          post :create, data: params[:data], format: :json
        end

        it { expect(json[:errors]).to be_nil }
        it { expect(response.status).to eql 201 }
        it { expect(json[:data][:attributes][:title]).to eql params[:data][:attributes][:title] }
        it { expect(User.find(user.id).user_profile.settings(:counters).total_tips).to be > 0 }

        it 'creates subtopic connections' do
          subtopic_ids_to_match = json[:data][:relationships][:subtopics][:data].map { |subtopic| subtopic[:id] }
          expect(subtopic_ids_to_match).to include(topic.children[0].id.to_s)
          expect(subtopic_ids_to_match).to_not include(topic.children[1].id.to_s)
        end

        # it 'creates root topic connections' do
        #   root_topic_ids_to_match = json[:data][:relationships][:topics][:data].map { |topic| topic[:id] }
        #   expect(root_topic_ids_to_match).to include(topic.id.to_s)
        #   expect(root_topic_ids_to_match).to include(topic_no_children.id.to_s)
        # end

        it 'makes user an admin' do
          expect(user.has_role?(:admin, Tip.last)).to eql(true)
        end
      end

      context 'when user_followers are present' do
        let(:user_list) { create_list(:user, 2) }

        before do
          params
          params[:data][:relationships][:user_followers] = {
            data: [{ id: user_list[0].id, type: 'users' }, { id: user_list[1].id, type: 'users' }],
          }

          post :create, data: params[:data], include: 'share_settings', format: :json
        end

        skip 'creates user connections' do
          user_ids_to_match = json[:data][:relationships][:user_followers][:data].map { |user| user[:id] }
          expect(user_ids_to_match).to include(user_list.first.id.to_s)
        end

        it 'does not create override share_settings' do
          selected_list = json[:included].reduce([]) { |a,u| a.push(u[:attributes][:sharing_object_id]) if u[:type] == 'share_settings'; a }
          expect(selected_list - user_list.map(&:id)).to be_empty
        end
      end

      context 'when sending empty user followers' do
        before do
          params[:data][:relationships][:user_followers] = { data: [] }

          post :create, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:created) }

      end
      
      context 'when topic has share settings' do
        let(:shared_topic) { create(:topic, user: user) }
        let(:group) { create(:group) }
        
        before do
          shared_topic.find_or_create_share_settings_for(user)
          shared_topic.find_or_create_share_settings_for(group)
          params[:data][:relationships] = {
            user_followers: { data: [] },
            share_settings: { data: [] },
            subtopics: { data: [{ id: shared_topic.id, type: 'topics'}] }
          }

          post :create, data: params[:data], include: 'share_settings', format: :json
        end

        it 'inherits share settings from topic' do
          tip = Tip.find(json[:data][:id])

          expect(tip.share_settings.where(
            sharing_object_id: user.id,
            sharing_object_type: 'User', 
          )).to_not be_empty
          
          expect(tip.share_settings.where(
            sharing_object_id: group.id,
            sharing_object_type: 'Group', 
          )).to_not be_empty
        end

        it { expect(json[:included].find { |setting|
          {
            sharing_object_id: group.id,
            sharing_object_type: 'groups',
            sharing_object_name: group.name
          } <= setting[:attributes]
        }).to_not be_nil }

        it { expect(json[:included].find { |setting|
          {
            sharing_object_id: user.id,
            sharing_object_type: 'users',
            sharing_object_name: user.name
          } <= setting[:attributes]
        }).to_not be_nil }

      end

      context 'when share_settings contains an email' do
        before do
          params
          params[:data][:relationships][:share_settings] = {
            data: [{ id: 'anthony@test.com', type: 'emails' }]
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(Invitation.count).to be > 0 }
        it { expect(Invitation.last.email).to eql 'anthony@test.com' }
      end

      context 'when share_settings are present' do
        let(:group_list) { create_list(:group, 2) }

        context 'when groups are only relationships' do
          before do
            params
            params[:data][:relationships][:share_settings] = {
              data: [{ id: group_list[0].id, type: 'groups' }, { id: group_list[1].id, type: 'groups' }]
            }

            post :create, data: params[:data], include: 'share_settings', format: :json
          end

          it { expect(response).to have_http_status(:created) }

          it 'creates group connections' do
            created_tip = Tip.find(json[:data][:id])
            group_ids_to_match = created_tip.group_followers.map { |group| group.id.to_s }
            expect(group_ids_to_match).to include(group_list.first.id.to_s)
          end

          it 'only creates group share_settings' do
            selected_list = json[:included].reduce([]) { |a,u| a.push(u[:attributes][:sharing_object_type]) if u[:type] == 'share_settings'; a }
            unique_list = selected_list.uniq
            expect(unique_list.size).to eql 1
            expect(unique_list.first).to eql 'groups'
          end
        end

        context 'when shared with everyone also' do
          before do
            params
            params[:data][:relationships][:share_settings] = {
              data: [
                { id: group_list[0].id, type: 'groups' },
                { id: group_list[1].id, type: 'groups' },
                { id: 'everyone', type: 'users' }
              ]
            }

            post :create, data: params[:data], format: :json
          end

          it { expect(response).to have_http_status(:created) }

          it 'creates group connections' do
            tip = Tip.find(json[:data][:id])
            group_shares = tip.share_settings.select { |setting| setting.sharing_object_type == 'Group' }
            group_ids_to_match = group_shares.map { |group_share| group_share.sharing_object_id.to_s }
            expect(group_ids_to_match).to include(group_list.first.id.to_s)
          end

          it 'also creates everyone connection' do
            expect(json[:data][:attributes][:share_public]).to be true
          end
        end
      end

      context 'when labels are present' do
        let(:label) { create(:label, kind: 'public') }

        context 'when there are existing labels applied' do
          before do
            params
            params[:data][:relationships][:labels] = {
              data: [{ id: label.id, type: 'labels' }]
            }

            post :create, data: params[:data], format: :json
          end

          it { expect(response).to have_http_status(:created) }
          it { expect(json[:data][:relationships][:labels][:data]).to_not be_empty }
        end
      end

      context 'when creating a nested tip' do
        let(:parent_tip) { create(:tip, user: user) }
        before do
          parent_tip.follow(topic)
          params[:data][:relationships][:parent_tip] = { data: { id: parent_tip.id, type: 'tips' } }
          params[:data][:relationships][:follows_tip] = { data: { id: parent_tip.id, type: 'tips' } }

          post :create, data: params[:data], format: :json
        end
        it { expect(response).to have_http_status(:created) }
        it { expect(json[:data][:attributes][:title]).to eql 'Test Tip' }
        it { expect(json[:data][:relationships][:follows_tip][:data]).not_to be_nil }
      end

      context 'without creating a nested tip' do
        let(:parent_tip) { create(:tip, user: user) }
        before do
          parent_tip.follow(topic)
          params[:data][:relationships][:parent_tip] = { data: { id: parent_tip.id, type: 'tips' } }

          post :create, data: params[:data], format: :json
        end
        it { expect(response).to have_http_status(:created) }
        it { expect(json[:data][:attributes][:title]).to eql 'Test Tip' }
        it { expect(json[:data][:relationships][:follows_tip][:data]).to be_empty}
      end

      xit 'belongs to the right user' do
        # How would we test this correctly?
      end
    end

    context "when giving a topic that doesn't exist" do
      before do
        params[:data][:relationships][:subtopics][:data] << { type: 'topics', title: 'A new day' }
      end

      context 'when the topic is a hive (root)' do
        before do
          post :create, data: params[:data], format: :json
        end

        it 'creates a new root topic' do
          topic = Topic.find_by(title: 'A new day')
          expect(topic).to_not be_nil
          expect(topic.ancestry).to be_nil
        end
      end

      context 'when the topic is a subtopic' do
        before do
          new_topic_options = { type: 'topics', title: 'A new day subtopic', parent_id: topic.id }
          params[:data][:relationships][:subtopics][:data] << new_topic_options
          post :create, data: params[:data], format: :json
        end

        it 'creates a new subtopic' do
          subtopic = Topic.find_by(title: 'A new day subtopic')
          expect(subtopic).to_not be_nil
          expect(subtopic.ancestry).to_not be_nil
        end
      end

      context 'when share_settings is present' do
        let(:user_list) { create_list(:user, 2) }

        before do
          params
          params[:data][:relationships][:share_settings] = {
            data: [{ id: user_list[0].id, type: 'users' }, { id: user_list[1].id, type: 'users' }]
          }

          post :create, data: params[:data], format: :json
          @new_topic = Topic.where(title: 'A new day').last
        end

        it 'shares new topic with user list' do
          share_settings = @new_topic.share_settings
          expect(share_settings.map { |setting| setting.sharing_object }).to include(user_list.first)
          expect(share_settings.map { |setting| setting.sharing_object }).to include(user_list.last)
        end

        it 'makes user list followers' do
          expect(@new_topic.user_followers).to include(user_list.first)
        end
      end

      context 'when share with group is present' do
        let(:group_list) { create_list(:group, 2) }

        before do
          params
          params[:data][:relationships][:share_settings] = {
            data: [{ id: group_list[0].id, type: 'groups' }, { id: group_list[1].id, type: 'groups' }]
          }

          post :create, data: params[:data], format: :json
        end

        it 'shares new topic with group list' do
          new_topic = Topic.where(title: 'A new day').last
          #share_settings = new_topic.share_settings.select { |setting| setting.sharing_object_type == 'Group' }
          expect(new_topic.share_settings.map { |setting| setting.sharing_object }).to include(group_list.first)
          expect(new_topic.group_followers).to include(group_list.first)
        end
      end
    end

    context 'when sending nil relationships' do
      let(:params_nil) do
        {
          data: {
            type: 'tips',
            attributes: {
              title: 'Test Tip',
              body: FFaker::Lorem.paragraphs(2).join("\n")
            },
            relationships: {
              subtopics: {
                data: nil
              },
              labels: {
                data: [{ id: '', type: 'labels' }]
              },
              user_followers: {
                data: nil
              },
              group_followers: {
                data: nil
              },
              attachments: {
                data: [{ id: '', type: 'attachments' }]
              },
              parent_tip: {
                data: nil
              }
            }
          }
        }
      end

      context 'when ONLY nils' do
        before do
          post :create, data: params_nil[:data], format: :json
        end

        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'when sending parent_tip' do
        let(:parent_tip) { create(:tip) }

        before do
          params_nil[:data][:relationships] = {
            parent_tip: {
              data: { id: parent_tip.id, type: 'tips' }
            }
          }

          post :create, data: params_nil[:data], format: :json
        end

        it { expect(response).to have_http_status(:created) }
        it { expect(Tip.find(parent_tip.id).tip_followers.count).to eql 0 }
      end

      context 'it should create version' do
        before :each do
          post :create, data: params[:data], format: :json
        end

        it {expect(PaperTrail).to be_enabled}
        it {expect(json[:data][:relationships][:versions][:data].length).to eql(1)} #Versioning is disabled on create
      end
    end
  end

  describe 'PUT/PATCH #update', versioning: true do
    context 'when valid attributes' do
      let(:tip) { create(:tip, user: user) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 2, user: user) }
      let(:topic_no_children) { create(:topic, user: user) }
      let(:topic_to_drop) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: user) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            attributes: {
              title: 'An updated title',
              start_date: Time.zone.today,
              due_date: Time.zone.today + 2,
              work_estimation: 16
            },
            relationships: {
              subtopics: {
                data: [
                  { id: topic.children[0].id, type: 'topics' }
                ]
              }
            }
          }
        }
      end

      before :each do
        tip
        tip.follow_multiple_resources(:topics, tiphive_serialize(topic_to_drop.children.to_a).as_json)

        tip.follow(topic_no_children)

        patch :update,
              id: tip.id,
              data: params[:data],
              format: :json
      end

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated title' }
      it { expect(json[:data][:attributes][:start_date]).to_not be_nil }
      it { expect(json[:data][:attributes][:due_date]).to_not be_nil }
      it { expect(json[:data][:attributes][:work_estimation]).to eql 16 }
      it { expect(json[:data][:id]).to eql tip.id.to_s }
      it { expect(json[:data][:relationships][:subtopics][:data].count).to eql 1 }

      it 'contains correct topics' do
        topic_ids = json[:data][:relationships][:topics][:data].map { |t| t[:id] }
        it { expect(topic_ids).to include(topic.id.to_s) }
        it { expect(topic_ids).to_not include(topic_no_children.id.to_s) }
        it { expect(topic_ids).to_not include(topic_to_drop.id.to_s) }
      end

      it {expect(PaperTrail).to be_enabled}
      it {expect(json[:data][:relationships][:versions][:data].length).to eql(2)} #Versioning is disabled on create
    end

    # ON HOLD: until we need to require attributes
    context 'when not owned by user' do
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 2, user: user) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            attributes: {
              title: 'An updated title'
            },
            relationships: {
              subtopics: {
                data: [
                  { id: topic.children[0].id, type: 'topics' }
                ]
              }
            }
          }
        }
      end

      let(:tip) { create(:tip) }

      context 'when authorized as owner' do
        let(:tip) { create(:tip, user: user) }

        before :each do
          patch :update, id: tip.id, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(200) }
      end

      context 'when authorized as resource admin' do
        before :each do
          user.add_role :admin, tip
          patch :update, id: tip.id, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(200) }
      end

      context 'when authorized as admin' do
        before :each do
          user.add_role :admin, domain
          patch :update, id: tip.id, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(200) }
      end

      context 'when shared with group' do
        let (:tip) { create(:tip, user: user) }
        let (:subtopic) { create(:topic, parent: topic) }
        let(:group) { create(:group) }
        let (:params) do
          {
            relationships: {
              share_settings: {
                data: [
                  { id: group.id, type: 'groups' }
                ]
              }
            }
          }
        end

        before do
          tip.follow(subtopic)
          patch :update, id: tip.id, data: params, format: :json
        end

        it { expect(Follow.find_by(
          followable_id: subtopic.id,
          followable_type: 'Topic',
          follower_id: group.id,
          follower_type: 'Group'
        )).to_not be nil }
        
        
        it { expect(Follow.find_by(
          followable_id: subtopic.id,
          followable_type: 'Topic',
          follower_id: group.id,
          follower_type: 'Group'
        )).to_not be nil }

      end
    end
    # make sure we updated the correct tip
    # make sure we can't change certain attributes

    context 'when labels are present' do
      let(:tip) { create(:tip, user: user) }
      let(:label0) { create(:label, name: 'Bookmark1', user_id: user.id, kind: 'public') }
      let(:label1) { create(:label, name: 'Bookmark2', user_id: user.id, kind: 'public') }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            attributes: {
              title: tip.title
            },
            relationships: {
              labels: {
                data: [
                  { id: label1.id, type: 'labels' }
                ]
              }
            }
          }
        }
      end

      context 'when there are existing labels applied' do
        before do
          patch :update, id: tip.id, data: params[:data], format: :json
        end

        it 'has a new label added' do
          expect(tip.label_assignments.map(&:label_id)).to include(label1.id)
        end

        it 'returns the new label in response' do
          label_list = json[:data][:relationships][:labels][:data]

          expect(label_list.map { |label| label[:id] }).to include(label1.id.to_s)
        end
      end

      context 'when labels are removed' do
        before do
          tip.label_assignments.create(label_id: label0.id)

          patch :update, id: tip.id, data: params[:data], format: :json
        end

        it 'removes labels that were not included in the list' do
          label_list = json[:data][:relationships][:labels][:data]

          expect(label_list.map { |label| label[:id] }).to include(label1.id.to_s)
          expect(label_list.map { |label| label[:id] }).to_not include(label0.id.to_s)
        end
      end
    end

    context 'when making private' do
      let(:public_tip) { create(:tip, user: user, share_public: true) }
      let(:shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: public_tip.id,
            type: 'tips',
            attributes: public_tip.attributes,
            relationships: {
              share_settings: {
                data: [{ id: 'private', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        public_tip
        public_tip.share_settings.create(user: user, sharing_object: shared_user)

        patch :update, id: public_tip.id, data: params[:data], format: :json
        @updated_tip = Tip.find(json[:data][:id])
      end

      it { expect(@updated_tip.private?).to be true }
      it { expect((@updated_tip.user_followers - [user]).size).to eql(0) }
      it { expect(@updated_tip.share_settings.length).to eql 0 }
      it { expect(json[:data][:attributes][:share_public]).to be false }
      it { expect(json[:data][:attributes][:share_following]).to be false }
    end

    context 'when sharing with users and card in public topic' do
      let(:topic) { create(:topic) }
      let(:tip_to_share) { create(:tip, user: user, share_public: true) }
      let(:users) { create_list(:user, 2) }

      let(:params) do
        {
          data: {
            id: tip_to_share.id.to_s,
            type: 'tips',
            attributes: tip_to_share.attributes.merge({ share_public: false }),
            relationships: {
              share_settings: {
                data: users.collect {|user| { id: user.id.to_s, type: 'users' } }
              },
              subtopics: {
                data: [{ id: topic.id.to_s, type: 'topics' }]
              }
            }
          }
        }
      end

      before do
        topic_preferences = topic.topic_preferences.for_user(user)
        topic_preferences.share_public = true
        topic_preferences.save
        tip_to_share.follow(topic)
        patch :update, id: tip_to_share.id, data: params[:data], format: :json
      end
      it { expect(json[:data][:attributes][:share_public]).to be false }
      it { expect(json[:data][:relationships][:share_settings][:data].count).to eql(2) }

    end
  end

  describe 'PUT/PATCH #update' do
    context 'with expiration date' do
      let(:tip) { create(:tip, user: user) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 2, user: user) }
      let(:expiration_date) { 2.days.since(Time.zone.now) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            attributes: {
              title: 'An updated title',
              expiration_date: expiration_date
            },
            relationships: {
              subtopics: {
                data: [
                  { id: topic.children[0].id, type: 'topics' }
                ]
              }
            }
          }
        }
      end

      before :each do
        patch :update,
              id: tip.id,
              data: params[:data],
              format: :json
      end

      it 'works' do
        expect(json[:errors]).to be_nil
        expect(response.status).to eql 200
      end

      it 'contains expected values' do
        expect(json[:data][:attributes][:title]).to eql 'An updated title'
        expect(json[:data][:attributes][:expiration_date]).to_not be_nil
        expect(json[:data][:attributes][:is_disabled]).to eql false
      end

      it { expect(TipExpirationWorker.jobs.count { |job| job['args'] == ['will_expire', "#{tip.id}"] }).to eql 1 }
      it { expect(TipExpirationWorker.jobs.count { |job| job['args'] == ['expire', "#{tip.id}"] }).to eql 1 }
    end
  end

  describe 'PUT/PATCH #update with new links' do
    let(:test_links) { build_test_links }
    let(:new_paragraph) { "Testing one link: \n http://www.apple.com" }
    let(:tip) { create(:tip, body: test_links.join("\n"), user_id: user.id) }

    let(:params) do
      {
        data: {
          id: tip.id,
          type: 'tips',
          attributes: {
            title: 'An updated title',
            body: new_paragraph
          }
        }
      }
    end

    before do
      tip.process_attachments_as_json

      patch :update, id: tip.id, data: params[:data], format: :json
    end

    it 'updated attachments_json' do
      attachments_json = json[:data][:attributes][:attachments_json]
      expect(attachments_json[:tip_links].count).to eql 1
    end
  end

  describe 'POST #share_with_relationships', skip: 'share_with_relationships is not used in front end' do
    let(:tip) { create(:tip, user: user, share_public: false) }

    context 'when valid attributes' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            relationships: {
              user_followers: {
                data: shared_users.collect { |user| { id: user.id, type: 'users' } }
              }
            }
          }
        }
      end

      before do
        post :share_with_relationships, id: tip.id, data: params[:data], format: :json
      end

      it { expect(tip.user_followers.where.not(id: tip.user_id).count).to eql(2) }
      it { expect(json[:data][:relationships][:share_settings][:data].count).to eql(2) }

    end

    context 'when making private' do
      let(:public_tip) { create(:tip, user: user, share_public: true) }
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: public_tip.id,
            type: 'tips',
            relationships: {
              user_followers: {
                data: [{ id: shared_users[0].id, type: 'users' }, { id: 'private', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        public_tip.share_settings.create(user: user, sharing_object: shared_users[0])
        public_tip.share_settings.create(user: user, sharing_object: shared_users[1])

        post :share_with_relationships, id: public_tip.id, data: params[:data], format: :json
      end

      it { expect(json[:data][:attributes][:share_public]).to be false }
      it { expect(json[:data][:attributes][:share_following]).to be false }
    end

    context 'when sharing with everyone' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            relationships: {
              user_followers: {
                data: [{ id: 'everyone', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        post :share_with_relationships, id: tip.id, data: params[:data], format: :json
      end

      it { expect(json[:data][:attributes][:share_following]).to be false }
      it { expect(json[:data][:attributes][:share_public]).to be true }
    end

    context 'when sharing with following' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            relationships: {
              user_followers: {
                data: [{ id: 'following', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        post :share_with_relationships, id: tip.id, data: params[:data], format: :json
      end

      it { expect(json[:data][:attributes][:share_following]).to be true }
      it { expect(json[:data][:attributes][:share_public]).to be false }
    end

    context 'when sharing with groups' do
      let(:shared_groups) { create_list(:group, 2) }
      let(:non_shared_group) { create(:group) }

      let(:params) do
        {
          data: {
            id: tip.id,
            type: 'tips',
            relationships: {
              group_followers: {
                data: shared_groups.collect { |group| { id: group.id, type: 'groups' } }
              }
            }
          }
        }
      end

      before do
        post :share_with_relationships, id: tip.id, data: params[:data], format: :json
      end

      it { expect(tip.group_followers.count).to eql(2) }
    end
  end

  describe 'DELETE #destroy' do
    context 'when owned by user' do
      let(:tip_list) { create_list(:tip, 2, user: user) }

      before do
        tip_list
        delete :destroy, id: tip_list[0].id, format: :json
      end

      it { expect(response.status).to eql 204 }
      it { expect(User.find(user.id).user_profile.settings(:counters).total_tips).to eql 1 }
    end

    context 'when authorized as admin' do
      let(:tip) { create(:tip) }

      before do
        user.add_role :admin, domain
        delete :destroy, id: tip.id, format: :json
      end

      it { expect(response.status).to eql 204 }

      # with_versioning do
      #   it { expect(PaperTrail::Version.where(item_type: 'Tip', item_id: tip.id, event: 'destroy').count).to be >= 1 }
      # end Now versioning is performed only on Update, SO no need of this.
    end
  end

  describe 'POST #flag' do
    let(:tip) { create(:tip, user: user) }

    let(:params) do
      {
        data: {
          id: tip.id,
          type: 'tips',
          reason: 'Flagger Reason'
        }
      }
    end

    before do
      post :flag, id: tip.id, data: params[:data], format: :json
    end

    it { expect(Flag.count).to eql 1 }
    it { expect(response).to have_http_status(:ok) }
    it { expect(json).to_not be_nil }
  end

  describe 'POST #like' do
    let(:tip) { create(:tip, user: user) }

    let(:params) do
      {
        data: {
          id: tip.id,
          type: 'tips'
        }
      }
    end

    before do
      post :like, id: tip.id, data: params[:data], format: :json
    end

    it { expect(tip.find_votes_for(vote_scope: :like).size).to eql 1 }
  end

  describe 'POST #unlike' do
    let(:tip) { create(:tip, user: user) }

    let(:params) do
      {
        data: {
          id: tip.id,
          type: 'tips'
        }
      }
    end

    before do
      post :like, id: tip.id, data: params[:data], format: :json
    end

    it { expect(tip.find_votes_for(vote_scope: :like).size).to eql 1 }
  end

  describe 'POST #star' do
    let(:tip) { create(:tip, user: user) }

    let(:params) do
      {
        data: {
          id: tip.id,
          type: 'tips'
        }
      }
    end

    before do
      post :star, id: tip.id, data: params[:data], format: :json
    end

    it { expect(tip.find_votes_for(vote_scope: :star).size).to eql 1 }
  end

  describe 'POST #unstar' do
    let(:tips) { create_list(:tip, 2, user: user) }

    let(:params) do
      {
        data: {
          id: tips.first.id,
          type: 'tips'
        }
      }
    end

    before do
      tips.each do |tip|
        VoteService.add_vote(user, tip, :star)
      end

      post :unstar, id: tips.last.id, data: params[:data], format: :json
    end

    it { expect(user.votes.size).to eql 1 }
    it { expect(user.voted_for?(tips.first, vote_scope: :star)).to be true }
  end

  describe 'POST #reorder' do
    let(:bob_tip) { create(:tip, title: 'A') }
    let(:mary_tip) { create(:tip, title: 'B') }
    let(:sally_tip) { create(:tip, title: 'C') }
    let(:topic) { create(:topic) }
    let(:harry) { create(:user, first_name: 'Harry') }

    context 'when moving to 1st position with no context_id' do
      let(:params) do
        {
          data: {
            topic_id: topic.id,
            preceding_tips: []
          }
        }
      end

      before do
        bob_tip.follow(topic)
        mary_tip.follow(topic)
        sally_tip.follow(topic)
      end

      context 'when topic_id is present' do
        before do
          post :reorder, id: sally_tip.id, data: params[:data], format: :json
        end

        it { expect(response.status).to eql 200 }

        it 'orders correctly within topic' do
          context_join = build_context_join(
            user: user,
            domain: current_domain,
            topic: topic
          )

          tip_ids = Tip.all.pluck(:id)

          tips_from_context = Tip.enabled.joins(context_join)
                              .select('tips.*, context_tips.position')
                              .where('tips.id IN (?)', tip_ids)
                              .order('context_tips.position')

          expect(tips_from_context.map(&:title)).to eql %w(C A B)
        end
      end

      context 'when topic_id is not present' do
        before do
          params[:data].delete(:topic_id)

          post :reorder, id: sally_tip.id, data: params[:data], format: :json
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
      end
    end

    context 'when reordering amongst several tips in a topic' do
      let(:params) do
        {
          data: {
            topic_id: topic.id,
            preceding_tips: [bob_tip.id.to_s]
          }
        }
      end

      before do
        [bob_tip, mary_tip, sally_tip].each do |tip|
          tip.follow topic
        end

        current_domain

        post :reorder, id: sally_tip.id, data: params[:data], format: :json
      end

      it 'moves sally between bob and mary within the topic' do
        context_join = build_context_join(
          user: user,
          domain: current_domain,
          topic: topic
        )

        tip_ids = Tip.all.pluck(:id)
        tips_from_context = Tip.enabled.joins(context_join)
                            .select('tips.*, context_tips.position')
                            .where('tips.id IN (?)', tip_ids)
                            .order('context_tips.position')

        expect(tips_from_context.map(&:title)).to eql %w(A C B)
      end

      it { expect(json[:data][:attributes][:position]).to eql 2 }
    end

    context 'when including someone elses context id when no context exists' do
      let(:params) do
        {
          data: {
            topic_id: topic.id,
            preceding_tips: [bob_tip.id],
            context_id: build_context_join(user: harry, domain: current_domain, topic: topic)
          }
        }
      end

      before do
        [bob_tip, mary_tip, sally_tip].each do |tip|
          tip.follow topic
        end

        post :reorder, id: sally_tip.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context 'when context_ids exist' do
      let(:params) do
        {
          data: {
            topic_id: topic.id,
            preceding_tips: [bob_tip.id]
          }
        }
      end

      before do
        [bob_tip, mary_tip, sally_tip].each do |tip|
          tip.follow topic
        end
      end

      context 'when changing own order' do
        before do
          context_id = Context.generate_id(
            user: user.id,
            domain: current_domain.id,
            topic: topic.id
          )

          local_context = Context.create(context_uniq_id: context_id, default: true)

          [bob_tip, mary_tip, sally_tip].each_with_index do |tip, index|
            local_context.context_tips.create(tip_id: tip.id, position: index + 1)
          end

          params[:data][:context_id] = context_id

          post :reorder, id: sally_tip.id, data: params[:data], format: :json
        end

        it { expect(ContextTip.count).to eql 3 }
        it { expect(ContextTip.find_by(tip_id: sally_tip.id).position).to eql 2 }
      end

      context 'when changing harrys order' do
        before do
          context_id = Context.generate_id(
            user: harry.id,
            domain: current_domain.id,
            topic: topic.id
          )

          local_context = Context.create(context_uniq_id: context_id, default: true)

          local_context.context_tips.create(tip_id: sally_tip.id, position: 1)
          local_context.context_tips.create(tip_id: mary_tip.id, position: 2)
          local_context.context_tips.create(tip_id: bob_tip.id, position: 3)

          params[:data][:context_id] = context_id
          params[:data][:preceding_tips] = [mary_tip.id, bob_tip.id]

          post :reorder, id: sally_tip.id, data: params[:data], format: :json
        end

        it { expect(ContextTip.count).to eql 3 }
        it { expect(ContextTip.find_by(tip_id: sally_tip.id).position).to eql 3 }
      end
    end
  end

  describe 'POST #archive' do
    context 'when creator' do
      let(:tip) { create(:tip, user: user) }

      before do
        post :archive, id: tip.id, format: :json
      end

      it { expect(json[:data][:attributes][:is_disabled]).to be true }
    end

    context 'when not creator' do
      let(:bob) { create(:user, first_name: 'Bob') }
      let(:tip) { create(:tip, user: bob) }

      before do
        post :archive, id: tip.id, format: :json
      end

      # it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end
  end

  describe 'POST #unarchive' do
    let(:tip) { create(:tip, user: user) }

    before do
      tip.archive!
      post :unarchive, id: tip.id, format: :json
    end

    it { expect(json[:data][:attributes][:is_disabled]).to be false }
  end

  describe 'GET #assigned_to' do
    it 'should create users, tips, assign tips to users and count assigned_to tips for users' do

      john = User.create!(email: "john@email.com", first_name: "John", last_name: "Doe", username: "john", password: "pass@123", password_confirmation: "pass@123")
      jane = User.create!(email: "jane@email.com", first_name: "jane", last_name: "Doe", username: "jane", password: "pass@123", password_confirmation: "pass@123")

      user.follow(john)

      ids = [john.id, jane.id]

      tip1 = Tip.create!(title: "Tip A", user: user)
      tip2 = Tip.create!(title: "Tip B", user: user)
      tip3 = Tip.create!(title: "Tip C", user: jane)
      tip4 = Tip.create!(title: "Tip D", user: john)

      TipAssignment.create!(tip_id: tip1.id, assignment_id: john.id, assignment_type: "User")
      TipAssignment.create!(tip_id: tip2.id, assignment_id: jane.id, assignment_type: "User")
      TipAssignment.create!(tip_id: tip3.id, assignment_id: jane.id, assignment_type: "User")

      get :assigned_to, user_ids: ids, format: :json
    
      expect(json[:data].count).to eql 2
    end
  end

  with_versioning do
    describe 'GET #fetch_versions #It fetch all versions of any tip.' do
      context "it shouldn't have any version as versioning is disabled on create" do
        let(:tip) { create(:tip) }

        before do
          get :fetch_versions, id: tip.to_param, format: :json
        end

        it { expect(response).to have_http_status(:success) }
        it { expect(json[:data].count).to eql(0) }
      end

      context "it should have versions as versioning is performend on update" do
        let(:tip) { create(:tip) }

        before do
          tip.update_attribute(:body, "this is new body")
          get :fetch_versions, id: tip.to_param, format: :json
        end

        it { expect(response).to have_http_status(:success) }
        it { expect(json[:data].count).to eql(1) }
      end
    end
  end
end
