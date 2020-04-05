require 'rails_helper'

describe V2::TopicsController do
  let(:user) { User.first || create(:user) }
  let(:bob) { User.find_by(first_name: 'Bob') || create(:user, first_name: 'Bob') }
  let(:mary) { User.find_by(first_name: 'Mary') || create(:user, first_name: 'Mary') }
  let(:sally) { User.find_by(first_name: 'Sally') || create(:user, first_name: 'Sally') }

  before do
    user.join(Domain.find_by(tenant_name: 'app'))
    request.headers['Authorization'] ||= "Bearer #{user.auth_token}"
    request.host = 'api.tiphive.dev'
  end

  describe 'GET index' do
    let(:parent_topic) { create(:topic, title: 'Parent Topic', user_id: user.id) }
    let(:topics_to_follow) { create_list(:topic, 3) }
    let(:topics_to_not_follow) { create_list(:topic, 2) }

    before do
      topics_to_follow
      topics_to_not_follow

      topics_to_follow.each_with_index do |topic, index|
        user.follow(topic)
        topic.update_attribute(:created_at, topic.created_at - (index + 1).months)
        topic.update_attribute(:title, ('A'..'Z').to_a[index] * 20)
      end
    end

    context 'when default order' do
      # NOTE: default scope is followed by user as of 2017-11-02
      before do
        get :index, format: :json
      end

      it { expect(response.status).to eql(200) }
      it { expect(json[:data].count).to eql(3) }
      it { expect(json[:data].first[:attributes][:title]).to eql('A' * 20) }
      it { expect(json[:data].last[:attributes][:title]).to eql('C' * 20) }
      it { expect(json[:data].first[:attributes][:parent_user]).not_to be_nil}
    end

    context 'when ordered in ascending order' do
      before do
        get :index, sort: { created_at: :asc }, format: :json
      end

      it { expect(json[:data].count).to eql(3) }
      it { expect(json[:data].first[:attributes][:created_at].to_date).to eql(Time.zone.today - 3.months) }
      it { expect(json[:data].last[:attributes][:created_at].to_date).to eql(Time.zone.today - 1.months) }
      it { expect(response.status).to eql(200) }
    end

    context 'when some topics are custom ordered' do
      before do
        first_topic = Topic.find_by(title: 'A' * 20)
        second_topic = Topic.find_by(title: 'C' * 20)

        context_id = Context.generate_id(
          user: user.id,
          domain: current_domain.id
        )

        local_context = Context.find_or_create_by(context_uniq_id: context_id)

        local_context.reorder(first_topic, 1)
        local_context.reorder(second_topic, 2)

        get :index, format: :json
      end

      it 'returns topics in correct order' do
        topic_array = json[:data].map { |topic| topic[:attributes][:title] }
        expect(topic_array).to eql ['A' * 20, 'C' * 20, 'B' * 20]
      end
    end

    context 'when including a parent_id' do
      before do
        create_list(:topic, 2, parent: topics_to_follow[0], user: user)
        create(:topic, parent: topics_to_follow[1])
        get :index, parent_id: topics_to_follow.first.id, format: :json
      end

      it { expect(json[:data].count).to eql(2) }
    end
  end

  describe 'GET index as guest' do
    let(:topic_to_follow) { create(:topic) }
    let(:topic_to_share) { create(:topic) }
    let(:topic_followed_by_group) { create(:topic) }
    let(:topic_to_not_follow) { create(:topic) }
    let(:group) { create(:group) }
    let(:new_owner) { create(:user) }

    before do
      topic_to_not_follow

      # Make a new user the domain owner so we can test user as a guest
      current_domain.update_attribute(:user_id, new_owner.id)
      user.leave(current_domain)
      user.join(current_domain, as: 'guest')

      # Share the topic with guest
      allow(Topic).to receive(:shared_with).and_return(
        Topic.where(id: topic_to_follow)
      )
    end

    context 'when searching all hives' do
      before do
        allow(Topic).to receive(:shared_with).and_return(
          Topic.where(id: topic_to_share)
        )
        get :index, format: :json, data: { search_all_hives: true }
      end

      it "only return shared topic" do
        expect(json[:data].count).to eql 1
        expect(json[:data][0][:id].to_i).to eql topic_to_share.id
      end
    end

    context 'when following a topic' do
      before do
        user.follow(topic_to_follow)

        get :index, format: :json
      end

      it { expect(json[:data].count).to eql 1 }
    end

    context 'when inside a group' do
      before do
        user.follow(topic_to_follow)
        user.follow(group)
        group.follow(topic_followed_by_group)

        get :index, filter: { within_group: group.id }, format: :json
      end

      it { expect(json[:data].count).to eql 1 }
    end
  end

  describe 'GET index with filters' do
    let(:topics_to_follow) { create_list(:topic, 3) }
    let(:topics_to_not_follow) { create_list(:topic, 2) }

    before do
      topics_to_follow
      topics_to_not_follow

      topics_to_follow.each_with_index do |topic, index|
        user.follow(topic)
        topic.update_attribute(:created_at, topic.created_at - (index + 1).months)
        topic.update_attribute(:title, ('A'..'Z').to_a[index] * 20)
      end
    end

    context 'when no filters' do
      before do
        get :index, format: :json
      end

      it { expect(json[:meta][:total_count]).to eql 3 }
    end

    context 'when search_all_hives' do
      before do
        get :index, search_all_hives: true, format: :json
      end

      it { expect(json[:meta][:total_count]).to eql 5 }
    end

    context 'filter by following' do
      before do
        get :index, filter: { followed_by_user: user.id }, format: :json
      end

      it { expect(json[:meta][:total_count]).to eql 3 }
    end

    context 'filter by not following' do
      before do
        get :index, filter: { not_followed_by_user: user.id }, format: :json
      end

      it { expect(Topic.count).to eql 5 }
      it { expect(json[:meta][:total_count]).to eql 2 }
    end

    context 'filter by shared_with' do
      before do
        topics_to_follow.last.find_or_create_share_settings_for(user)

        get :index, filter: { shared_with: user.id }, format: :json
      end

      it { expect(json[:meta][:total_count]).to eql 1 }
    end

    context 'filter by starred' do
      before do
        VoteService.add_vote(user, topics_to_not_follow.first, :star)

        get :index, filter: { type: 'starred' }, format: :json
      end

      it { expect(json[:data].count).to eql 1 }
    end
  end

  describe 'GET index scoped by group with filters' do
    let(:topics_to_follow) { create_list(:topic, 3) }
    let(:topics_to_not_follow) { create_list(:topic, 2) }
    let(:group) { create(:group, user_id: user.id) }

    before do
      topics_to_follow
      topics_to_not_follow

      topics_to_follow.each_with_index do |topic, index|
        user.follow(topic)
        topic.update_attribute(:created_at, topic.created_at - (index + 1).months)
        topic.update_attribute(:title, ('A'..'Z').to_a[index] * 20)
      end
    end

    context 'filter by group' do
      before do
        topics_to_follow.first(2).each do |topic|
          group.follow(topic)
        end

        get :index, filter: { within_group: group.id }, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end

    context 'filter by group & only show topics followed' do
      before do
        topics_to_follow.first(2).each do |topic|
          group.follow(topic)
        end

        group.follow(topics_to_not_follow.first)

        get :index, filter: { within_group: group.id, followed_by_user: user.id }, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end

    context 'filter by group & shared_with' do
      before do
        topics_to_follow.first.find_or_create_share_settings_for(user)

        topics_to_follow.first(2).each do |topic|
          group.follow(topic)
        end

        get :index, filter: { within_group: group.id, shared_with: user.id }, format: :json
      end

      it { expect(json[:data].count).to eql 1 }
    end

    context 'filter by group && starred' do
      let(:lunch) { create(:topic, title: 'Lunch') }
      let(:dinner) { create(:topic, title: 'Dinner') }

      before do
        VoteService.add_vote(user, lunch, :star)
        VoteService.add_vote(user, dinner, :star)

        group.follow(lunch)

        get :index, filter: { within_group: group.id, type: :starred }, format: :json
      end

      it { expect(json[:data].first[:attributes][:title]).to eql 'Lunch' }
    end
  end

  describe 'GET index with descendants' do
    let(:root) { create(:topic, user: user, title: 'One') }
    let(:child) { create(:topic, user: user, parent: root, title: 'Child') }
    let(:grandchild) { create(:topic, user: user, parent: child, title: 'grandchild') }

    context 'when not passing with_details' do
      before do
        grandchild
        get :index, format: :json
      end

      it { expect(json[:data].first).to_not have_key(:relationships) }
    end
  end

  describe 'GET show as guest' do
    let(:topic_to_share) { create(:topic) }
    let(:topic_to_not_share) { create(:topic) }
    let(:group) { create(:group) }
    let(:new_owner) { create(:user) }

    before do
      topic_to_not_share

      # Make a new user the domain owner so we can test user as a guest
      current_domain.update_attribute(:user_id, new_owner.id)
      user.leave(current_domain)
      user.join(current_domain, as: 'guest')

      # Share the topic with guest
      allow(Topic).to receive(:shared_with).and_return(
        Topic.where(id: topic_to_share)
      )
    end

    context 'when accessing shared topic' do
      before do
        get :show, id: topic_to_share, format: :json
      end

      it { expect(response.status).to eql(200) }
    end

    context 'when accessing not shared topic' do
      before do
        get :show, id: topic_to_not_share, format: :json
      end

      it { expect(response.status).to eql(401) }
    end

  end

  describe 'GET show' do
    let(:topic) { create(:topic, user: user, title: 'Parent Topic') }
    let(:tips) { create_list(:tip, 2, user: user) }
    let(:rogue_tips) { create_list(:tip, 3, user: user) }
    let(:aaa) { create(:topic, title: 'AAA', parent_id: topic.id) }
    let(:bbb) { create(:topic, title: 'BBB', parent_id: topic.id) }
    let(:ccc) { create(:topic, title: 'CCC', parent_id: topic.id) }

    before do
      rogue_tips

      tips.each do |tip|
        tip.follow(topic)
      end
    end

    context 'when using a valid id' do
      before :each do
        get :show, id: topic, format: :json
      end

      it { expect(response.status).to eql(200) }
      it { expect(json[:data][:attributes][:title]).to eql topic.title }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(json[:data][:attributes][:tip_count]).to eql 2 }
      it { expect(json[:data][:attributes][:show_tips_on_parent_topic]).to eql true }

      it 'has one preferences record' do
        expect(json[:data][:relationships][:topic_preferences][:data].count).to be >= 1
      end
    end

    context 'when using the correct slug' do
      before :each do
        user.follow(topic)
        get :show,
            id: "#{topic.id}-#{topic.title.parameterize}",
            format: :json
      end

      it { expect(json[:data][:id]).to eql topic.id.to_s }
    end

    context 'when using a bad slug' do
      before :each do
        user.follow(topic)
        get :show,
            id: "#{topic.id}-#{topic.title.parameterize}-bad-slug",
            format: :json
      end

      xit { expect(response).to redirect_to(action: :show, id: topic) }

      it 'the redirect location path matches the good slug' do
        new_slug = URI.parse(response.location).path.split('/').last
        expect(new_slug).to eql topic.slug
      end
    end

    context 'when given blank id' do
      before :each do
        user.follow(topic)
        get :show,
            id: '',
            format: :json
      end

      it { expect(response.status).to eql 401 }
      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end

    context 'when share_settings exist' do
      let(:users) { create_list(:user, 2) }

      before do
        users.each { |user| user.join(current_domain, as: 'member') }
        topic.share_with_relationships('user', UserSmallSerializer.new(users))
        get :show, id: topic, format: :json
      end

      it { expect(json[:errors]).to be_nil }

      it 'has a user share_setting' do
        settings = json[:data][:relationships][:share_settings][:data]
        expect(settings.map { |setting| setting[:sharing_object_type] }).to include('users')
      end

      it 'creates share settings' do
        topic = Topic.find(json[:data][:id])
        expect(topic.share_settings).to_not be_nil
      end
    end

    context 'when custom ordered subtopics exist' do
      let(:bob) { create(:user, first_name: 'Bob') }

      before do
        aaa
        bbb
        ccc

        first_topic = Topic.find_by(title: 'A' * 20)
        second_topic = Topic.find_by(title: 'C' * 20)

        context_id = Context.generate_id(
          user: user.id,
          domain: current_domain.id,
          topic: topic.id
        )

        local_context = Context.find_or_create_by(context_uniq_id: context_id)

        bob_context_id = Context.generate_id(
          user: bob.id,
          domain: current_domain.id,
          topic: topic.id
        )

        Context.find_or_create_by(context_uniq_id: bob_context_id)

        local_context.reorder(first_topic, 1)
        local_context.reorder(second_topic, 2)

        get :show, id: topic, format: :json
      end

      it { expect(topic.children.count).to eql 3 }
      it { expect(json[:data][:relationships][:contexts][:data].count).to eql 2 }
    end
  end

  describe 'GET show - authorization' do
    context 'when authorized to read' do
      let(:topic) { create(:topic, user: user) }

      before :each do
        get :show, id: topic, format: :json
      end

      it { expect(response.status).to eql(200) }
    end
  end # show - authorization

  describe 'POST create - authorization' do
    let(:member) { create(:user) }
    let(:topic) { build(:topic, user: user) }
    let(:default_view) { View.find_or_create_by(kind: 'system', name: 'grid') }

    let(:params) do
      {
        data: {
          type: 'topics',
          attributes: {
            title: topic.title,
            description: topic.description,
            default_view_id: default_view.id
          },
          relationships: {
            topic_preferences: {
              data: [
                {
                  type: 'topic_preferences'
                }.merge(attributes_for(:topic_preference))
              ]
            },
            topic_permission: {
              data: {
                access_hash: {
                  create_topic:     { roles: ['member'] },
                  edit_topic:       {},
                  destroy_topic:    {},
                  create_tip:       { roles: ['member'] },
                  edit_tip:         {},
                  destroy_tip:      {},
                  like_tip:         { roles: ['member'] },
                  comment_tip:      { roles: ['member'] },
                  create_question:  { roles: ['member'] },
                  edit_question:    {},
                  destroy_question: {},
                  like_question:    { roles: ['member'] },
                  answer_question:  {}
                }
              }
            },
            roles: {
              data: [
                {
                  user_id: member.id,
                  name: 'admin'
                }
              ]
            }
          }
        }
      }
    end

    context 'when authorized to create' do
      before do
        post :create, data: params[:data], format: :json
      end

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 201 }
      it do
        permissions = json[:data][:relationships][:topic_permission]
        data = permissions[:data][:access_hash][:answer_question]
        expect(data).to eq({})
      end
      it do
        topic = Topic.find json[:data][:id]
        expect(member.has_role? 'admin', topic)
      end

      it { expect(json[:data][:attributes][:default_view_id]).to eql View.find_by(name: 'grid').id.to_s }
    end

    context 'when guest user' do
      let(:new_owner) { create(:user) }

      before do
        # Make user a guest
        user.leave(current_domain)

        # Make a new user the domain owner so we can test user as a guest
        current_domain.update_attribute(:user_id, new_owner.id)
        user.join(current_domain, as: 'guest')

        post :create, data: params[:data], format: :json
      end

      it { expect(user.member_of?(current_domain)).to be false }
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end # create authorization

  describe 'POST create - authorization when not allowed to create' do
    # let(:domain) { create(:domain, user: member) }
    let(:member) { create(:user) }
    let(:topic) { build(:topic) }

    let(:params) do
      {
        data: {
          type: 'topics',
          attributes: {
            title: topic.title,
            description: topic.description
          },
          relationships: {
            topic_preferences: {
              data: [
                {
                  type: 'topic_preferences'
                }.merge(attributes_for(:topic_preference))
              ]
            }
          }
        }
      }
    end

    before do
      # change owner of domain so that user isn't able to create a topic
      current_domain.update_attributes(
        user_id: member.id,
        domain_permission_attributes: {
          access_hash: {
            create_topic:     {},
            edit_topic:       {},
            destroy_topic:    {},
            create_tip:       { roles: ['member'] },
            edit_tip:         {},
            destroy_tip:      {},
            like_tip:         { roles: ['member'] },
            comment_tip:      { roles: ['member'] },
            create_question:  { roles: ['member'] },
            edit_question:    {},
            destroy_question: {},
            like_question:    { roles: ['member'] },
            answer_question:  { roles: ['member'] }
          }
        }
      )

      current_domain.reload
    end

    context 'when not authorized to read' do
      before :each do
        post :create, data: params[:data], format: :json
      end

      # it { expect(response).to have_http_status(401) }
      it { expect(json[:errors]).to eql(title: 'You are not authorized to perform that request.') }
    end
  end # create - authorization

  describe 'POST create' do
    let(:topic) { build(:topic, user: user) }

    context 'when valid attributes' do
      let(:params) do
        {
          data: {
            type: 'topics',
            attributes: {
              title: topic.title,
              description: topic.description
            },
            relationships: {
              topic_preferences: {
                data: [
                  {
                    type: 'topic_preferences' # TODO: Test this in topic_controller
                  }.merge(attributes_for(:topic_preference))
                ]
              }
            }
          }
        }
      end

      before :each do
        post :create,
             data: params[:data],
             format: :json
      end

      # it { expect(params).to be_nil }

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 201 }
      it { expect(json[:data][:attributes][:title]).to eql topic[:title] }
      it { expect(json[:data][:relationships][:topic_preferences][:data].count).to be >= 1 }

      # it 'creates a context' do
      #   expect(Context.where(topic: json[:data][:id], user: user).count).to be > 0
      # end

      xit 'belongs to the right user' do
        # How would we test this correctly?
      end

      it 'makes user an admin' do
        expect(user.has_role?(:admin, Topic.last)).to eql(true)
      end
    end

    context 'when share_settings are present' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            type: 'topics',
            attributes: {
              title: topic.title,
              description: topic.description
            },
            relationships: {
              share_settings: {
                data: shared_users.collect { |user| { id: user.id, type: 'users' } }
              }
            }
          }
        }
      end

      context 'without Everyone or Following overrides' do
        before :each do
          post :create,
               data: params[:data],
               format: :json
        end

        it { expect(json[:errors]).to be_nil }
        it { expect(response.status).to eql 201 }

        it 'has 2 expected followers plus 1 creator follower' do
          expect(Topic.find(json[:data][:id]).user_followers.count).to eql(3)
        end

        it 'creates share settings' do
          topic = Topic.find(json[:data][:id])
          expect(topic.share_settings).to_not be_nil
        end

        it 'has correct topic_preferences followers' do
          topic = Topic.find(json[:data][:id])
          expect(topic.topic_preferences.for_user(shared_users.first).follow_all_users?).to be true
        end
      end

      context 'with Everyone override' do
        before :each do
          params[:data][:relationships][:share_settings][:data] << {
            id: 'everyone',
            type: 'users'
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(response.status).to eql 201 }

        it 'sets topic_preference share_everyone to true' do
          expect(Topic.find(json[:data][:id]).topic_preferences.for_user(user).share_public).to be true
        end
      end

      context 'with Following override' do
        before :each do
          params[:data][:relationships][:share_settings][:data] << {
            id: 'Following',
            type: 'users'
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(response.status).to eql 201 }

        it 'sets topic_preference share_following to true' do
          # TODO: Write test, share_following may or may not be the answer
        end
      end

      context 'when user_followers contains an email' do
        before :each do
          params[:data][:relationships][:share_settings][:data] << {
            id: 'anthony@test.com',
            type: 'emails'
          }

          post :create, data: params[:data], format: :json
        end

        it { expect(Invitation.count).to be > 0 }
        it { expect(Invitation.last.email).to eql 'anthony@test.com' }
      end
    end

    context 'when group_followers are present' do
      let(:shared_groups) { create_list(:group, 2) }
      let(:group_user) { create(:user) }

      let(:params) do
        {
          data: {
            type: 'topics',
            attributes: {
              title: topic.title,
              description: topic.description
            },
            relationships: {
              share_settings: {
                data: shared_groups.collect { |group| { id: group.id, type: 'groups' } }
              }
            }
          }
        }
      end

      before :each do
        group_user.follow(shared_groups.first)
        post :create,
             data: params[:data],
             format: :json
      end

      it { expect(json[:errors]).to be_nil }
      it { expect(response.status).to eql 201 }
      it { expect(Topic.find(json[:data][:id]).group_followers.count).to eql(2) }
    end

    context 'when creating a subtopic' do
      let(:topic) { create(:topic, title: 'Root') }
      let(:parent) { create(:topic, title: 'Parent', parent: topic) }
      let(:subtopic) { build(:topic, title: 'SubTopic') }

      let(:params) do
        {
          data: {
            type: 'topics',
            attributes: {
              title: subtopic.title,
              description: subtopic.description,
              parent_id: parent.id
            }
          }
        }
      end

      context 'and following root and not parent' do
        before :each do
          Sidekiq::Testing.inline! do
            user.stop_following(parent)

            post :create,
                 data: params[:data],
                 format: :json
          end
        end

        it { expect(Topic.find(json[:data][:id]).parent).to_not be_nil }
        it { expect(user.following_topics).to include(topic) }

        it 'the user should not be a follower' do
          json_user_id = Topic.find(json[:data][:id]).user_followers
          expect(json_user_id).to be_empty
        end
      end

      context 'when following parent' do
        before :each do
          Sidekiq::Testing.inline! do
            user.follow(parent)

            post :create,
                 data: params[:data],
                 format: :json
          end
        end

        it 'returns the user as a follower' do
          json_user_id = Topic.find(json[:data][:id]).user_followers.first[:id].to_s
          expect(json_user_id).to eql user.id.to_s
        end
      end
    end

    context 'when uid nil' do
      let(:topic_attributes) { attributes_for(:topic) }

      let(:params) do
        {
          data: {
            type: 'topics',
            attributes: topic_attributes
          }
        }
      end

      before :each do
        request.headers['Authorization'] = ''
        post :create,
             data: params[:data],
             format: :json
      end

      # TODO: This needs to be tested against the new authentication
      # TODO: we need to conform the error messages coming from authentication to the JSONAPI
      # with an ErrorSerializer or somehing
      it { expect(response.status).to eql 401 }
      it { expect(json[:error]).to_not be_nil }
    end

    context 'when type is wrong' do
      let(:topic_attributes) { attributes_for(:topic) }

      let(:params) do
        {
          data: {
            type: 'not_topics',
            attributes: topic_attributes
          }
        }
      end

      before :each do
        post :create,
             data: params[:data],
             format: :json
      end

      it { expect(response.status).to eql 422 }
      it { expect(json[:errors]).to_not be_nil }
    end

    context 'when creating with conflicting title' do
      let(:existing_topic) { create(:topic, title: 'My Topic', user: user) }

      context 'when creating a Hive with same title' do
        let(:params) do
          {
            data: {
              type: 'topics',
              attributes: {
                title: 'My Topic',
                description: topic.description
              }
            }
          }
        end

        before do
          existing_topic

          post :create,
               data: params[:data],
               format: :json
        end
        # it should send a 409 with a URL to the duplicate

        it { expect(response.status).to eql 200 }
        it { expect(json[:meta][:message]).to_not be_nil }
      end

      context 'when creating a SubTopic at same level' do
        let(:hive) { create(:topic, title: 'My Hive Title') }
        let(:existing_subtopic) { create(:topic, title: 'My SubTopic Title', parent_id: hive.id) }

        let(:params) do
          {
            data: {
              type: 'topics',
              attributes: {
                title: existing_subtopic.title,
                description: 'A description',
                parent_id: hive.id
              }
            }
          }
        end

        before :each do
          hive
          existing_subtopic
          post :create,
               data: params[:data],
               format: :json
        end
        # it should send a 409 with a URL to the duplicate
        it { expect(response.status).to eql 200 }
        it { expect(json[:meta][:message]).to_not be_nil }
      end
    end

    # once we decide the multi-tenancy, make sure the topic belongs to the right domain
  end

  describe 'PUT/PATCH update' do
    context 'when valid attributes' do
      let(:topic) { create(:topic, user: user) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title',
              show_tips_on_parent_topic: false,
            }
          }
        }
      end

      before :each do
        patch :update,
              id: topic.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:attributes][:show_tips_on_parent_topic]).to eql false }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
    end
    # make sure we can't change certain attributes

    context 'when valid attributes with topic preference' do
      let(:topic) { create(:topic, user: user) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title'
            },
            relationships: {
              topic_preferences: {
                data: [
                  {
                    type: 'topic_preferences' # TODO: Test this in topic_controller
                  },
                  share_following: false
                ]
              }
            }
          }
        }
      end

      before :each do
        patch :update,
              id: topic.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
      it { expect(topic.topic_preferences.for_user(user).share_following).to eql(false) }
      it 'default value of show_tips_on_parent_topic is true' do
        expect(json[:data][:attributes][:show_tips_on_parent_topic]).to eql true
      end
    end

    context 'when adding share with people I follow' do
      let(:topic) { create(:topic, user: user) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title'
            },
            relationships: {
              topic_preferences: {
                data: [
                  {
                    type: 'topic_preferences' # TODO: Test this in topic_controller
                  }
                ]
              },
              share_settings: {
                data: [{ id: 'following', type: 'users' }]
              }
            }
          }
        }
      end

      before :each do
        patch :update,
              id: topic.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }

      it 'sets overrides correctly' do
        topic_with_overrides = Topic.find_by(id: json[:data][:id])
        expect(topic_with_overrides.topic_preferences.for_user(user).share_following).to be true
        expect(topic_with_overrides.topic_preferences.for_user(user).share_public).to be false
      end
    end

    context 'when changing parent' do
      let(:topic) { create(:topic, user: user) }
      let(:subtopic) { create(:topic, user: user, parent_id: topic.id) }
      let(:params) do
        {
          data: {
            id: subtopic.id,
            type: 'topics',
            attributes: {
              parent_id: '0'
            },
            relationships: {}
          }
        }
      end

      before do
        patch :update, id: subtopic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eq 200 }
      it { expect(Topic.find(subtopic.id).parent_id).to be_nil }
    end
  end

  describe 'POST #share_with_relationships' do
    let(:topic) { create(:topic, user: user) }
    let(:tips) { create_list(:tip, 3, user: user) }

    context 'when valid attributes' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: shared_users.collect { |user| { id: user.id, type: 'users' } }
              }
            }
          }
        }
      end

      before do
        tips.each { |tip| tip.follow(topic) }
        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(topic.user_followers.where.not(id: topic.user_id).count).to eql(2) }

      it 'include users as share_settings' do
        settings = json[:data][:relationships][:share_settings][:data]
        expect(settings.count).to eql(2)
      end

      it 'sets following_tips to have same followers' do
        tip_ids = topic.tip_followers.first.user_followers.pluck(:id)
        share_setting_ids = json[:data][:relationships][:share_settings][:data].map { |ss| ss[:sharing_object_id] }
        expect(share_setting_ids - tip_ids).to be_empty
      end
      # TODO: Add expectation for a notification
    end

    context 'when removing a user' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }
      let(:bob) { create(:user, first_name: 'Bob') }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              user_followers: {
                data: [{ id: shared_users[0].id, type: 'users' }]
              }
            }
          }
        }
      end

      before do
        topic.share_settings.create(
          user_id: user.id,
          sharing_object_id: bob.id,
          sharing_object_type: 'User'
        )

        shared_users.each { |user| user.follow(topic) }

        tips.each do |tip|
          tip.follow(topic)
          bob.follow(tip)
        end

        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(topic.user_followers.count).to eql(2) }
      it { expect(topic.user_followers.where.not(id: topic.user_id).count).to eql(1) }

      it 'include users as share_settings' do
        settings = json[:data][:relationships][:share_settings][:data]
        expect(settings.count).to eql(1)
      end
    end

    context 'when making private' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }
      let(:tip) { create(:tip, user: user, share_public: true) }
      let(:tip2) { create(:tip, user: user, share_public: true) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: [{ id: shared_users.first.id, type: 'users' }, { id: 'private', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        tip.follow(topic)

        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it 'includes private as a share setting' do
        settings = json[:data][:relationships][:share_settings][:data].map { |s| s[:sharing_object_id] }
        # expect(settings).to include('private')
        # expect(settings).to_not include(shared_users.first.id)
      end

      it 'makes following tips also private' do
        tips = Topic.find(json[:data][:id]).tip_followers
        expect(tips.first.share_following).to be false
        expect(tips.first.share_public).to be false
      end
    end

    # TODO: ADD TESTS TO ENSURE TIPS ARE SET TO SHARE PUBLIC AND FOLLOWING TOO

    context 'when sharing with everyone' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }
      let(:tip) { create(:tip, user: user, share_public: true) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: [{ id: 'everyone', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        tip.follow(topic)

        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:ok) }

      it 'includes everyone as a share setting' do
        settings = json[:data][:relationships][:share_settings][:data].map { |s| s[:sharing_object_id] }
        expect(settings).to include('everyone')
      end

      it 'sets overrides correctly' do
        topic = Topic.find_by(id: json[:data][:id])
        expect(topic.topic_preferences.for_user(user).share_following).to be false
        expect(topic.topic_preferences.for_user(user).share_public).to be true
      end

      it 'tips are also share_public' do
        tips = Topic.find(json[:data][:id]).tip_followers
        expect(tips.first.share_following).to be false
        expect(tips.first.share_public).to be true
      end
    end

    it 'when sharing with following', skip: 'post /share_with_relationships is not in use in front end' do
      let(:shared_users) { create_list(:user, 2) }
      let(:non_shared_user) { create(:user) }
      let(:tip) { create(:tip, user: user, share_public: true) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: [{ id: shared_users.first.id, type: 'users' }, { id: 'following', type: 'users' }]
              }
            }
          }
        }
      end

      before do
        tip.follow(topic)

        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it 'includes following as a share setting' do
        topic = Topic.find_by(id: json[:data][:id])
        expect(topic.topic_preferences.for_user(user).share_following).to be true
      end

      it 'includes user as a share setting' do
        settings = json[:data][:relationships][:share_settings][:data].map { |s| s[:sharing_object_id] }
        expect(settings).to include(shared_users.first.id)
      end

      it 'sets overrides correctly' do
        topic = Topic.find_by(id: json[:data][:id])
        expect(topic.topic_preferences.for_user(user).share_following).to be true
        expect(topic.topic_preferences.for_user(user).share_public).to be false
      end

      it 'tips are also share_following' do
        tips = Topic.find(json[:data][:id]).tip_followers
        expect(tips.first.share_following).to be true
        expect(tips.first.share_public).to be false
      end
    end

    context 'when sharing with a group' do
      let(:shared_groups) { create_list(:group, 2) }
      let(:non_shared_group) { create(:group) }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: shared_groups.collect { |group| { id: group.id, type: 'groups' } }
              }
            }
          }
        }
      end

      before do
        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(topic.group_followers.count).to eql(2) }
      # TODO: Add expectation for a notification
    end

    context 'when removing a group' do
      let(:shared_group) { create(:group) }
      let(:shared_group_2) { create(:group) }
      let(:bob) { create(:user, first_name: 'Bob') }

      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            relationships: {
              share_settings: {
                data: [
                  { id: shared_group_2.id, type: 'groups' },
                  { id: bob.id, type: 'users' }
                ]
              }
            }
          }
        }
      end

      before do
        topic.share_settings.create(
          user_id: user.id,
          sharing_object_id: shared_group.id,
          sharing_object_type: 'Group'
        )

        shared_group.follow(topic)

        post :share_with_relationships, id: topic.id, data: params[:data], format: :json
      end

      it { expect(topic.group_followers.count).to eql(1) }
      it { expect(topic.user_followers.map { |u| u[:id] }).to include bob.id.to_i }
      it { expect(topic.group_followers[0][:id]).to eql(shared_group_2.id.to_i) }
    end # When removing a group
  end

  describe 'DELETE #destroy - authorization' do
    let(:member) { create(:user) }
    let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }

    before do
      tip.follow(topic)
      second_tip.follow(topic)
    end

    context 'when authorized as owner' do
      let(:tip) { create(:tip, user: user) }
      let(:second_tip) { create(:tip, user: user) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: user) }

      before { delete :destroy, id: topic.id, format: :json }

      it { expect(response.status).to eql 204 }
    end

    context 'when authorized as admin' do
      let(:tip) { create(:tip, user: member) }
      let(:second_tip) { create(:tip, user: member) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: member) }

      before do
        user.add_role :admin, domain
        delete :destroy, id: topic.id, format: :json
      end

      it { expect(response.status).to eql 204 }
    end

    context 'when authorized as topic admin' do
      let(:tip) { create(:tip, user: member) }
      let(:second_tip) { create(:tip, user: member) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: member) }

      before do
        user.add_role :admin, topic
        delete :destroy, id: topic.id, format: :json
      end

      it { expect(response.status).to eql 204 }
    end
  end # destroy - authorization

  describe 'PATCH #update - authorization' do
    let(:member) { create(:user) }
    let(:domain) { Domain.find_by(tenant_name: Apartment::Tenant.current) }
    let(:topic) { create(:topic, user: user) }
    let(:topic2) { create(:topic, user: member) }

    before do
      member.join(domain)
    end

    context 'when authorized as owner' do
      let(:params) do
        {
          data: {
            id: topic.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title'
            }
          }
        }
      end

      before do
        patch :update,
              id: topic.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic.id.to_s }
    end

    # context 'when not authorized' do
    #   let(:params) do
    #     {
    #       data: {
    #         id: topic2.id,
    #         type: 'topics',
    #         attributes: {
    #           title: 'An updated topic title'
    #         }
    #       }
    #     }
    #   end

    #   before do
    #     patch :update,
    #           id: topic2.id,
    #           data: params[:data],
    #           format: :json
    #   end

    #   it { expect(response.status).to eql 401 }
    # end

    context 'when authorized as admin' do
      let(:params) do
        {
          data: {
            id: topic2.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title'
            }
          }
        }
      end

      before do
        user.add_role :admin, domain
        patch :update,
              id: topic2.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic2.id.to_s }
    end

    context 'when authorized as topic admin' do
      let(:params) do
        {
          data: {
            id: topic2.id,
            type: 'topics',
            attributes: {
              title: 'An updated topic title'
            }
          }
        }
      end

      before do
        user.add_role :admin, topic2
        patch :update,
              id: topic2.id,
              data: params[:data],
              format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(json[:data][:attributes][:title]).to eql 'An updated topic title' }
      it { expect(json[:data][:id]).to eql topic2.id.to_s }
    end
  end # update - authorization

  with_versioning do
    describe 'DELETE #destroy' do
      let(:tip) { create(:tip, user: user) }
      let(:second_tip) { create(:tip, user: user) }
      let(:third_tip) { create(:tip, user: user) }
      let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: user) }
      let(:alternate_topic) { create(:topic) }
      let(:subtopic) { topic.children.first }
      let(:tip_id) { tip.id }
      let(:second_tip_id) { second_tip.id }
      let(:topic_id) { topic.id }
      let(:subtopic_id) { subtopic.id }

      before do
        subtopic

        tip.follow(topic)
        second_tip.follow(topic)
        third_tip.follow(subtopic)
      end

      context 'when topic has subtopics and tips' do
        before { delete :destroy, id: topic.id, format: :json }

        it { expect(response.status).to eql 204 }
        it do
          expect(PaperTrail::Version.where(
            item_type: 'Topic',
            item_id: topic_id,
            event: 'destroy'
          ).count).to be >= 1
        end
        it do
          expect(PaperTrail::Version.where(
            item_type: 'Topic',
            item_id: subtopic_id,
            event: 'destroy'
          ).count).to be >= 1
        end

        it 'archives all tips' do
          expect(tip.reload.is_disabled?).to be true
          expect(second_tip.reload.is_disabled?).to be true
          expect(third_tip.reload.is_disabled?).to be true
        end
      end

      context 'when topic has subtopics and tips and move all' do
        before do
          delete :destroy, id: topic.id, data: {
            alternate_topic_id: alternate_topic.id,
            move_tip_ids: 'all'
          }, format: :json
        end

        it { expect(response.status).to eql 204 }
        it do
          expect(PaperTrail::Version.where(
            item_type: 'Topic',
            item_id: topic_id,
            event: 'destroy'
          ).count).to be >= 1
        end

        it 'reassigns subtpic' do
          expect(subtopic.reload.parent_id).to eql alternate_topic.id
        end

        it { expect(alternate_topic.tip_followers.count).to eql 2 }
      end

      context 'when subtopic owned by a user' do
        let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 1, user: user) }
        let(:subtopic) { topic.children.first }

        before do
          delete :destroy, id: subtopic.id, format: :json
        end

        it { expect(response.status).to eql 204 }

        it 'has a version with a destroy event' do
          versions = PaperTrail::Version.where(item_type: 'Topic', item_id: subtopic.id, event: 'destroy')

          expect(versions.count).to be >= 1
        end
      end
    end
  end

  describe 'POST #move' do
    let(:topic) { create(:topic, :with_subtopics, number_of_subtopics: 3, user: user) }
    let(:alternate_topic) { create(:topic, user: user) }

    let(:params) do
      {
        data: {
          alternate_topic_id: alternate_topic.id
        }
      }
    end

    context 'move topic to alternate topic' do
      before do
        post :move, id: topic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql 200 }
      it { expect(alternate_topic.descendants.count).to eql 4 }
      it do
        topic.reload
        expect(topic.descendants.count).to eql 3
      end
    end
  end

  describe 'POST #move with tips' do
    let(:fruit) { create(:topic, user: bob) }
    let(:types) { create(:topic, title: 'types', user: bob, parent_id: fruit.id) }
    let(:berries) { create(:topic, title: 'berries', user: bob, parent_id: types.id) }

    let(:colors) { create(:topic, title: 'colors', user: bob, parent_id: fruit.id) }
    let(:blue) { create(:topic, title: 'blue', user: bob, parent_id: colors.id) }
    let(:blueberries) { create(:topic, title: 'BlueBerries', user: bob, parent_id: blue.id) }

    # Tips to test assignment
    let(:blueberry_tips) { create_list(:tip, 2, user: bob) }

    let(:params) do
      {
        data: {
          alternate_topic_id: berries.id
        }
      }
    end

    context 'when normal move' do
      before do
        blueberry_tips.each do |tip|
          tip.follow(blueberries)
        end

        # move blueberries from blue to berries
        post :move, id: blueberries.id, data: params[:data], format: :json
      end

      it { expect(response).to have_http_status(:ok) }

      it 'has the correct parent id' do
        parent_id = json[:data][:attributes][:parent_id].to_s
        expect(parent_id).to eql berries.id.to_s
      end

      it 'does not allow previous parent to view tips' do
        prev_parent = Topic.find_by(title: 'blue')
        expect(prev_parent.tip_followers.count).to eql 0
        expect(prev_parent.viewable_tips_for(user).count).to eql 0
      end
    end
  end

  describe 'POST #reorder' do
    let(:topic) { create(:topic) }
    let(:breakfast_topic) { create(:topic, title: 'A', parent_id: topic.id) }
    let(:lunch_topic) { create(:topic, title: 'B', parent_id: topic.id) }
    let(:dinner_topic) { create(:topic, title: 'C', parent_id: topic.id) }

    context 'when moving to 1st position' do
      let(:params) do
        {
          data: {
            preceding_topics: []
          }
        }
      end

      before do
        breakfast_topic
        lunch_topic
        dinner_topic

        post :reorder, id: dinner_topic.id, data: params[:data], format: :json
      end

      it { expect(response.status).to eql(200) }

      it 'orders correctly with no topic' do
        context_join = 'LEFT JOIN context_topics ON context_topics.topic_id = topics.id'
        context_join += " AND context_topics.context_id = 'user:#{user.id}:domain:#{current_domain.id}'"
        topic_ids = Topic.with_root.pluck(:id)

        topics_from_context = Topic.joins(context_join)
                              .select('topics.*, context_topics.position')
                              .where('topics.id IN (?)', topic_ids)
                              .order('context_topics.position')

        expect(topics_from_context.map(&:title)).to eql %w(C A B)
      end
    end

    context 'when reordering amongst several sub_topics in a topic' do
      let(:params) do
        {
          data: {
            topic_id: topic.id,
            preceding_topics: [breakfast_topic.id]
          }
        }
      end

      before do
        breakfast_topic
        lunch_topic
        dinner_topic

        post :reorder, id: dinner_topic.id, data: params[:data], format: :json
      end

      it 'moves dinner between breakfast and lunch within the topic' do
        context_id = "user:#{user.id}:domain:#{current_domain.id}:topic:#{topic.id}"
        context_join = 'LEFT JOIN context_topics ON context_topics.topic_id = topics.id'
        context_join += " AND context_topics.context_id = '#{context_id}'"
        topic_ids = Topic.with_root.pluck(:id)

        topics_from_context = Topic.joins(context_join)
                              .select('topics.*, context_topics.position')
                              .where('topics.id IN (?)', topic_ids)
                              .order('context_topics.position')

        expect(topics_from_context.map(&:title)).to eql %w(A C B)
      end
    end
  end

  describe 'POST join' do
    let(:topic) { create(:topic, title: 'Topic', user: bob) }
    let(:parent) { create(:topic, title: 'Parent', user: bob) }
    let(:subtopic) { create(:topic, title: 'SubTopic', parent: parent, user: bob) }

    context 'when joining root' do
      before do
        topic
        parent
        subtopic
        user.follow(topic)
        mary.follow(topic)
        post :join, id: topic.id, format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data][:id]).to eql(topic.id.to_s) }

      it 'includes the correct users' do
        it { expect(topic.user_followers).to include(user) }
        it { expect(topic.user_followers).to include(bob) }
        it { expect(subtopic.user_followers).to include(bob) }
        it { expect(subtopic.user_followers).to include(mary) }
      end

      it { expect(user.following_users).to_not include(bob) }
      it { expect(topic.topic_preferences.for_user(user).follow_all_users?).to be true }
    end

    context 'when joining a subtopic (parent)' do
      before do
        subtopic
        post :join, id: parent.id, format: :json
      end

      it { expect(subtopic.user_followers).to include(user) }
    end
  end

  describe 'POST leave' do
    let(:topic) { create(:topic, title: 'Topic', user: user) }
    let(:parent) { create(:topic, title: 'Parent', parent: topic, user: user) }
    let(:subtopic) { create(:topic, title: 'SubTopic', parent: parent, user: user) }

    context 'when leaving root' do
      before do
        subtopic
        user.follow(topic)
        post :leave, id: topic.id, format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data][:id]).to eql(topic.id.to_s) }
      it { expect(topic.user_followers).to_not include(user) }
      it { expect(subtopic.user_followers).to be_empty }
    end

    context 'when leaving parent' do
      before do
        subtopic
        user.follow(topic)
        post :leave, id: parent.id, format: :json
      end

      it { expect(subtopic.user_followers).to be_empty }
    end
  end

  describe 'POST #star' do
    let(:topic) { create(:topic, title: 'Star Me') }

    before do
      topic

      post :star, id: topic.id, format: :json
    end

    it 'stars the topic for the user' do
      vote_count = topic.find_votes_for(vote_scope: :star, voter_id: user.id).size
      expect(vote_count).to eql 1
    end

    it { expect(topic.find_votes_for(vote_scope: :like).size).to eql 0 }
  end

  describe 'GET explore' do
    let(:editor) { create(:user, email: 'daniel+tiphiveeditor@tiphive.com') }
    let(:topic_list) { create_list(:topic, 5) }

    before do
      topic_list.each { |topic| editor.follow(topic) }
      topic_list.first(3).each { |topic| user.follow(topic) }
    end

    context 'when no filters applied' do
      before do
        get :explore, format: :json
      end

      it { expect(Topic.count).to eql(5) }
      it { expect(response).to have_http_status(:ok) }
      it 'defaults to the 2 NON-FOLLOWED topics' do
        expect(json[:data].count).to eql(2)
      end
    end
  end

  describe 'GET suggested_topics' do
    let(:global_templates) { create_list(:global_template, 5, user: user) }

    before do
      global_templates
      user.join(current_domain)
    end

    context 'when no topics created' do
      before do
        get :suggested_topics, format: :json
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json[:data].count).to eql 5 }
    end

    context 'when some topics exist from the GlobalTemplates' do
      before do
        GlobalTemplate.where(template_type: 'Topic').first(3).each do |template|
          create(:topic, user: user, title: template.title)
        end

        get :suggested_topics, format: :json
      end

      it { expect(json[:data].count).to eql 2 }
    end
  end
end
