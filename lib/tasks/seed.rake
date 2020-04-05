require 'task_helpers'

namespace :seed do
  desc 'Build All Sample Data'
  task all: :environment do
    @tenant_name = 'demo-domain'
    @domain = build_domain

    Apartment::Tenant.switch @domain.tenant_name do
      @existing_users = build_existing_users
      build_topics
      build_tips
    end
  end

  desc 'Build Empty Domain'
  task empty: :environment do
    @tenant_name = 'autos'
    @domain = build_domain
  end

  def build_domain
    puts 'Building domain'
    clean_up_previous

    # Create the default user for our tests
    default_user =
      FactoryGirl.create(
        :user,
        first_name: 'Sally',
        last_name: 'Bee',
        password: 'demopassword',
        password_confirmation: 'demopassword',
        email: "sally@#{@tenant_name}.com"
      )

    # Create the default tenant for our tests
    Domain.create!(name: @tenant_name.gsub(/-/, ' ').titleize, user: default_user)
  end

  def user_list
    users = %w(bob mary harry john)

    users.map { |user| [user, @tenant_name].join('@') + '.com' }
  end

  def build_existing_users
    users = []
    user_list.each do |email|
      users << build_user(email)
    end

    users
  end

  def build_user(email)
    user =
      FactoryGirl.create(
        :user,
        email: email,
        first_name: email.split('@').first.capitalize,
        password: 'demopassword',
        password_confirmation: 'demopassword'
      )

    user.join(@domain)

    user
  end

  def build_topics
    puts "building topics for #{@domain.name}"
    @existing_users.each do |user|
      FactoryGirl.create(:topic, :with_subtopics, user_id: user.id)
    end
  end

  def build_tips
    puts "building tips for #{@domain.name}"

    Topic.with_root.all.each do |topic|
      print "#{topic.title}: "
      5.times do
        print '.'
        tip = FactoryGirl.create(:tip, user_id: topic.user_id)
        tip.follow(topic)
      end
      puts ''
    end
  end

  def clean_up_previous
    begin
      Apartment::Tenant.drop(@tenant_name)
    rescue Apartment::TenantNotFound
      nil
    end

    Domain.find_by(tenant_name: @tenant_name).try(:delete)
    user_list.each do |email|
      User.find_by(email: email).try(:destroy)
    end
    User.find_by(email: "sally@#{@tenant_name}.com").try(:destroy)

    # begin

    # rescue
    #   nil
    # end
  end
end
