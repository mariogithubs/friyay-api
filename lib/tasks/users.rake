namespace :users do
  desc 'Report of New Domain Users'
  task user_reports: :environment do
    domain_sql = "select dm.user_id, u.email, u.first_name, u.last_name, d.tenant_name AS domain, "
    domain_sql += "DATE(dm.created_at) AS \"Joined Domain\", DATE(u.created_at) AS \"Joined TipHive\" "
    domain_sql += "from domain_memberships dm join users u on u.id = dm.user_id join domains d "
    domain_sql += "on dm.domain_id = d.id where dm.created_at > #{Time.zone.yesterday} "
    domain_sql += "order by dm.created_at DESC;"

    results = ActiveRecord::Base.connection.execute(domain_sql)
    domain_users_csv = CSV.generate do |csv|
      csv << results.fields

      results.values.each do |row|
        csv << row
      end
    end

    users_sql = "select first_name, last_name, email, DATE(created_at) AS joined "
    users_sql += "from users where users.id NOT IN (select user_id from domain_memberships ) "
    users_sql += "and email NOT LIKE '%+%' and created_at > #{Time.zone.yesterday};"

    results = ActiveRecord::Base.connection.execute(users_sql)
    users_csv = CSV.generate do |csv|
      csv << results.fields

      results.values.each do |row|
        csv << row
      end
    end

    AdminMailer.delay.new_domain_members(domain_users_csv, users_csv)
  end

  desc 'Remove User from domain (interactive)'
  task remove: :environment do
    printf 'What is the tenant_name of the domain you want to remove the user? '
    tenant_name = STDIN.gets.chomp

    domain = Domain.find_by(tenant_name: tenant_name)
    puts 'Domain not found' unless domain
    next unless domain

    Apartment::Tenant.switch(tenant_name) do
      printf "What is the email of the user you want to remove from #{tenant_name}? "
      user_email = STDIN.gets.chomp

      user = User.find_by(email: user_email)
      puts 'User not found' if user.blank?
      next if user.blank?

      tips = user.tips
      topics = user.topics.without_root
      content = tips + topics

      puts "#{user_email} has #{tips.count} tips and #{topics.count} topics."
      printf "Do you want to remove or reassign all content from #{user_email} as well (yes/no)? "
      remove_content = STDIN.gets.chomp

      if remove_content == 'yes'
        remove_or_reassign(user, content)
      end

      user.leave!(domain)

      puts user_email + " removed from #{tenant_name}"
    end
  end

  desc 'Delete User (interactive)'
  task delete: :environment do
    puts "WARNING! This will delete the user. Perhaps you meant rake users:remove."
    printf "Continue (yes/no)? "
    next if STDIN.gets.chomp != 'yes'

    printf 'What is the email of the user you want to delete forever? '
    user_email = STDIN.gets.chomp

    user = User.find_by(email: user_email)
    puts 'User not found' if user.blank?
    next if user.blank?

    tips = user.tips
    topics = user.topics.without_root
    content = tips + topics

    puts "#{user_email} has #{tips.count} tips and #{topics.count} topics."
    printf "Do you want to remove all content from #{user_email} as well (yes/no)? "
    remove_content = STDIN.gets.chomp

    if remove_content == 'yes'
      delete_all_content(user, content)
    end

    user.destroy

    puts user_email + ' Deleted!'
  end

  desc 'Remove all follows of any user no longer a domain member'
  task remove_follows: :environment do
    Domain.all.each do |domain|
      Apartment::Tenant.switch domain.tenant_name do
        users = User.where(id: Follow.where(follower_type: 'User').pluck(:follower_id).uniq)

        puts "Removing follows from #{users.count} users still following something in #{domain.tenant_name}"

        users.each do |user|
          next if user.member_of?(domain) || user.power_of?(domain)
          next if user.follows.count == 0
          puts "User has #{user.follows.count} follows"
          user.follows.destroy_all
        end
      end
    end
  end

  desc 'Update Counters'
  task reset_counters: :environment do
    domains = Domain.select(:id, :tenant_name).all
    domains << Domain.new(tenant_name: 'public')

    domains.each do |domain|
      tenant_name = domain.tenant_name
      puts "Calculating #{tenant_name}"

      Apartment::Tenant.switch(tenant_name) do
        users = DomainMember.all unless tenant_name == 'public'
        users = User.all if tenant_name == 'public'

        users.includes(:user_profile).each do |user|
          profile = user.try(:user_profile)
          user.create_user_profile unless profile
          user.reload

          user.user_profile.reset_counters
        end
      end
    end
  end

  private

  def remove_or_reassign(user, content)
    printf "To whom do you wish to reassign all content (none/owner/USER EMAIL)? "
    reassign_to = STDIN.gets.chomp

    case reassign_to
    when 'none'
      delete_all_content(user, content)
      return
    when 'owner'
      new_owner = domain.user
    else
      new_owner = User.find_by(email: reassign_to)
    end

    puts 'New Owner not found' if new_owner.blank?
    return if new_owner.blank?

    reassign_content_to(new_owner, content)
  end

  def delete_all_content(user, content)
    puts "Deleting all content from #{user.email}."
    content.each do |item|
      item.destroy
      printf "."
    end
    puts "All content from #{user.email} deleted."
  end

  def reassign_content_to(new_owner, content)
    new_id = new_owner.id

    puts "Reassigning Content"
    content.each do |item|
      item.update_attribute(:user_id, new_id)
      printf "."
    end
    puts "Content Reassigned"
  end
end