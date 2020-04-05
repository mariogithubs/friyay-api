require 'task_helpers'

namespace :dev do
  # include TaskHelpers

  desc 'Follow All subtopics'
  task follow_all_subtopics: :environment do
    print 'Public? '
    process_public = STDIN.gets.chomp
    domains = ['y', 'yes'].include?(process_public) ? [Domain.new(tenant_name: 'public')] : process_public == 'tiphive' ? Domain.where(tenant_name: 'tiphiveteam') : Domain.all
    domains_count = domains.count

    domains.each_with_index do |domain, index|
      puts "Processing domain (#{index}/#{domains_count}: #{domain.tenant_name}..."
      Apartment::Tenant.switch(domain.tenant_name) do
        domain.users.each do |user|
          puts "Processing user: #{user.username}..."
          topics = user.following_topics.roots
          user_following_topic_ids = user.following_topics.pluck(:id)
          topics.each do |topic|
            descendant_ids = topic.descendant_ids - user_following_topic_ids
            puts 'No descendants to follow' if descendant_ids.empty?
            next if descendant_ids.empty?

            print "Processing #{descendant_ids.size} descendants "

            sql = "INSERT INTO \"#{domain.tenant_name}\".follows (followable_id, followable_type, follower_id, follower_type) VALUES "
            insert_values = "('%s', '%s', '%s', '%s'),"
            descendant_ids.each do |id|
              sql += insert_values % [id.to_s, 'Topic', user.id.to_s, 'User']
            end
            sql.chomp!(',')
            ActiveRecord::Base.connection.execute sql
            print "\n"
          end
        end
      end
      puts "\n========> Waiting 2 sec <===========\n"
      sleep 2
    end # domains
  end

  desc 'Reprocess all images'
  task reprocess_all_images: :environment do
    puts "reprocessing all domain-specific resource images"

    TaskHelpers.gather_domain_names.each do |domain_name|
      Apartment::Tenant.switch(domain_name) do
        TopicPreference.reprocess_images!
        Group.reprocess_images!
        Image.reprocess_images!
      end
    end
  end

  Rake::Task[:reprocess_all_images].enhance [:reprocess_global_images]

  desc 'Reprocess global images (users and domains)'
  task reprocess_global_images: :environment do
    puts "reprocessing all user and domain images"

    UserProfile.reprocess_images!
    Domain.reprocess_images!
  end

  desc 'Delete a Topic (also removes follows, subtopics & tips)'
  task delete_topic: :environment do
    print 'Domain Name: '
    domain_id = STDIN.gets.chomp
    domain = Domain.find_by(tenant_name: domain_id) || Domain.new(tenant_name: 'public')

    Apartment::Tenant.switch! domain.tenant_name

    print 'Topic ID: '
    topic_id = STDIN.gets.chomp
    topic = Topic.find_by(id: topic_id)

    puts 'Topic not found' if topic.blank?

    next if topic.blank?

    puts 'ARE YOU SURE YOU WANT TO DELETE THIS TOPIC AND ALL OF THE TIPS?'
    input = STDIN.gets.chomp

    next unless input == 'yes'

    subtopics = topic.descendants

    # followable_ids = subtopics.pluck(:id) << topic.id
    # follows = Follow.where(id: followable_ids, followable_type: 'Topic')

    tips = topic.tip_followers

    subtopics.each do |subtopic|
      tips << subtopic.tip_followers
    end

    tips = tips.flatten

    puts "#{tips.count} tips to be destroyed"

    tips.each do |tip|
      print "D"
      tip.destroy
    end

    puts "\n"

    subtopics.destroy_all
    topic.destroy

    puts "Topic: #{topic.id} has been destroyed"
  end

  desc 'Delete FriendList Followers'
  task delete_friend_lists: :environment do
    Domain.all.each do |domain|
      sql = "DELETE FROM \"#{domain.tenant_name}\".follows"
      sql += " WHERE follower_type='FriendList' OR followable_type='FriendList';"
      puts "Deleting FriendLists from follows for #{domain.tenant_name}"
      ActiveRecord::Base.connection.execute sql
    end

    sql = "DELETE FROM public.follows"
    sql += " WHERE follower_type='FriendList' OR followable_type='FriendList';"
    puts "Deleting FriendLists from follows for public domain"
    ActiveRecord::Base.connection.execute sql

    Domain.all.each do |domain|
      sql = "DELETE FROM \"#{domain.tenant_name}\".share_settings"
      sql += " WHERE sharing_object_type='FriendList' OR shareable_object_type='FriendList';"
      puts "Deleting FriendLists from share_settings for #{domain.tenant_name}"
      ActiveRecord::Base.connection.execute sql
    end

    sql = "DELETE FROM public.share_settings"
    sql += " WHERE sharing_object_type='FriendList' OR shareable_object_type='FriendList';"
    puts "Deleting FriendLists from share_settings for public domain"
    ActiveRecord::Base.connection.execute sql
  end

  desc 'Delete FriendList Followers'
  task delete_pockets: :environment do
    Domain.all.each do |domain|
      sql = "DELETE FROM \"#{domain.tenant_name}\".follows"
      sql += " WHERE follower_type='Pocket' OR followable_type='Pocket';"
      puts "Deleting Pockets from follows for #{domain.tenant_name}"
      ActiveRecord::Base.connection.execute sql
    end

    sql = "DELETE FROM public.follows"
    sql += " WHERE follower_type='Pocket' OR followable_type='Pocket';"
    puts "Deleting Pockets from follows for public"
    ActiveRecord::Base.connection.execute sql

    Domain.all.each do |domain|
      sql = "DELETE FROM \"#{domain.tenant_name}\".share_settings"
      sql += " WHERE sharing_object_type='Pocket' OR shareable_object_type='Pocket';"
      puts "Deleting Pockets from share_settings for #{domain.tenant_name}"
      ActiveRecord::Base.connection.execute sql
    end

    sql = "DELETE FROM public.share_settings"
    sql += " WHERE sharing_object_type='Pocket' OR shareable_object_type='Pocket';"
    puts "Deleting Pockets from share_settings for public"
    ActiveRecord::Base.connection.execute sql
  end

  desc 'Copy body to body_md'
  task copy_body: :environment do
    domains = Domain.all
    domains << Domain.new(tenant_name: 'public')
    domain_count = domains.size

    domains.each_with_index do |domain, index|
      puts "\n#{index + 1} of #{domain_count} Starting copy body for #{domain.name || 'Public'} \n*******************"

      Apartment::Tenant.switch domain.tenant_name do
        tips = Tip.where("created_at > ?", Time.now.beginning_of_day)
        next if tips.blank?

        tips.each do |tip|
          next if tip.body.blank?
          # Don't run callbacks, just move text and render text
          tip.update_columns(body_md: tip.body)
          print "."
        end

        puts "\n========> Waiting 10 sec <===========\n"
        # sleep 10
      end
    end
  end

  desc 'Convert Markdown Tips to HTML'
  task convert_md_html: :environment do
    class RenderWithNoPTags < Redcarpet::Render::HTML
      def paragraph(text)
        %(#{text}<br>)
      end
    end

    renderer = RenderWithNoPTags.new(hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, space_after_headers: true, autolink: true)
    domains = Domain.all
    domains << Domain.new(tenant_name: 'public')
    domain_count = domains.size

    domains.each_with_index do |domain, index|
      puts "\n#{index + 1} of #{domain_count} Starting convert_md_html for #{domain.name || 'Public'}\n*******************"

      Apartment::Tenant.switch domain.tenant_name do
        tips = Tip.where("created_at > ?", Time.now.beginning_of_day)
        next if tips.blank?

        tips.each do |tip|
          next if tip.body.blank?
          # Don't run callbacks, just move text and render text
          tip.update_columns(body: markdown.render(tip.body))
          print "."
        end

        puts "\n========> Waiting 10 sec <===========\n"
        # sleep 10
      end
    end
  end
end