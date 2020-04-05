# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# We need an initial user
User.create(
  first_name: 'Admin',
  last_name: 'Smith',
  email: 'admin@test.com',
  password: 'treeLeaf123',
  password_confirmation: 'treeLeaf123'
)

domain_one = FactoryGirl.create(
  :domain,
  name: 'Domain One',
  tenant_name: 'domain-one',
  user: User.first
)

users = FactoryGirl.create_list(:user, 5)
users.each { |user| user.join(domain_one) }

Apartment::Tenant.switch domain_one.tenant_name do
  users.each do |user|
    # Create some topics
    topic = FactoryGirl.create(:topic, user: user)

    # Create some subtopics
    subtopics = FactoryGirl.create_list(:subtopics, 2, user: user, parent_id: topic.id)

    # Create some tips in those topics
    [topic, subtopics].flatten.each do |local_topic|
      tips = FactoryGirl.create_list(:tip, 2, user: user)
      tips.each { |tip| tip.follow(local_topic) }
    end
  end
end

# Set up Support Domain
# After running this seed file, you'll need to plugin the id of this domain
# into the .env file

FactoryGirl.create(
  :domain,
  name: 'Support',
  tenant_name: 'support',
  user: User.first
)
